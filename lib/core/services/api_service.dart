import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import '../config/api_config.dart';
import '../exceptions/api_exception.dart';
import '../utils/connectivity_utils.dart';
import '../utils/logger.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  static ApiService get instance => _instance;

  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);
  static const int _maxCacheSize = 100; // Maximum number of cached responses
  
  String? _token;
  final http.Client _client;
  final Logger _logger;
  final Map<String, CachedResponse> _cache;
  final Duration _cacheExpiry;
  final _requestLocks = <String, Lock>{};

  ApiService._internal()
      : _client = http.Client(),
        _logger = Logger(),
        _cache = {},
        _cacheExpiry = const Duration(minutes: 5);

  void setToken(String? token) {
    _token = token;
  }

  // Wallet methods
  Future<Map<String, dynamic>> getWalletBalance() async {
    return get<Map<String, dynamic>>(
      '/wallet/balance',
      (json) => json,
    );
  }

  Future<List<Map<String, dynamic>>> getWalletTransactions({int page = 1}) async {
    return getList<Map<String, dynamic>>(
      '/wallet/transactions',
      (json) => json,
      queryParams: {'page': page},
    );
  }

  // Loan methods
  Future<List<Map<String, dynamic>>> getLoans() async {
    return getList<Map<String, dynamic>>(
      '/loans',
      (json) => json,
    );
  }

  Future<Map<String, dynamic>> applyForLoan(Map<String, dynamic> data) async {
    return post<Map<String, dynamic>>(
      '/loans/apply',
      data,
      (json) => json,
    );
  }

  Future<Map<String, dynamic>> rolloverLoan(Map<String, dynamic> data) async {
    return post<Map<String, dynamic>>(
      '/loans/rollover',
      data,
      (json) => json,
    );
  }

  // Contribution methods
  Future<List<Map<String, dynamic>>> getContributions() async {
    return getList<Map<String, dynamic>>(
      '/contributions',
      (json) => json,
    );
  }

  // Investment methods
  Future<List<Map<String, dynamic>>> getInvestments() async {
    return getList<Map<String, dynamic>>(
      '/investments',
      (json) => json,
    );
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-Version': '1.0.0',
      'X-Platform': Platform.operatingSystem,
      'X-Request-ID': _generateRequestId(),
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  String _generateRequestId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${1000 + DateTime.now().microsecond % 9000}';
  }

  Future<T> get<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    bool useCache = true,
    Duration? timeout,
    bool forceRefresh = false,
    Map<String, dynamic>? queryParams,
  }) async {
    final uri = Uri.parse(ApiConfig.baseUrl + endpoint).replace(
      queryParameters: queryParams?.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ).cast<String, String>(),
    );
    final cacheKey = '${uri.toString()}_${_token ?? 'no_auth'}';

    // Check cache if enabled and not forcing refresh
    if (useCache && !forceRefresh) {
      final cachedResponse = _cache[cacheKey];
      if (cachedResponse?.isValid(_cacheExpiry) ?? false) {
        _logger.debug('Cache hit for $endpoint');
        return fromJson(cachedResponse!.data);
      }
    }

    try {
      await _checkConnectivity();

      final response = await _retryWithTimeout(
        () => _client.get(uri, headers: _headers),
        timeout: timeout ?? _defaultTimeout,
      );

      final result = await _handleResponse(response, fromJson);

      // Cache the response if caching is enabled
      if (useCache) {
        _manageCache();
        _cache[cacheKey] = CachedResponse(
          data: jsonDecode(response.body),
          timestamp: DateTime.now(),
        );
      }

      return result;
    } on TimeoutException {
      throw ApiException(
        'Request timed out',
        errorData: {'statusCode': 408},
      );
    } catch (e) {
      _logger.error('GET $endpoint failed', e);
      rethrow;
    }
  }

  Future<T> post<T>(
    String endpoint,
    dynamic data,
    T Function(Map<String, dynamic>) fromJson, {
    List<FileUpload>? files,
    Duration? timeout,
    void Function(int sent, int total)? onProgress,
    bool idempotent = false,
  }) async {
    final uri = Uri.parse(ApiConfig.baseUrl + endpoint);
    final requestId = _generateRequestId();

    // For idempotent requests, use a lock to prevent duplicates
    if (idempotent) {
      final lock = _requestLocks.putIfAbsent(endpoint, () => Lock());
      return lock.synchronized(() => _executePost(
        uri,
        data,
        fromJson,
        files: files,
        timeout: timeout,
        onProgress: onProgress,
        requestId: requestId,
      ));
    }

    return _executePost(
      uri,
      data,
      fromJson,
      files: files,
      timeout: timeout,
      onProgress: onProgress,
      requestId: requestId,
    );
  }

  Future<T> _executePost<T>(
    Uri uri,
    dynamic data,
    T Function(Map<String, dynamic>) fromJson, {
    List<FileUpload>? files,
    Duration? timeout,
    void Function(int sent, int total)? onProgress,
    String? requestId,
  }) async {
    try {
      await _checkConnectivity();

      if (files != null && files.isNotEmpty) {
        return await _uploadFiles(
          uri,
          data,
          files,
          fromJson,
          timeout: timeout,
          onProgress: onProgress,
          requestId: requestId,
        );
      }

      final headers = {
        ..._headers,
        if (requestId != null) 'X-Request-ID': requestId,
      };

      final response = await _retryWithTimeout(
        () => _client.post(
          uri,
          headers: headers,
          body: jsonEncode(_sanitizeData(data)),
        ),
        timeout: timeout ?? _defaultTimeout,
      );

      return _handleResponse(response, fromJson);
    } on TimeoutException {
      throw ApiException(
        'Request timed out',
        errorData: {'statusCode': 408},
      );
    } catch (e) {
      _logger.error('POST ${uri.path} failed', e);
      rethrow;
    }
  }

  Future<T> _uploadFiles<T>(
    Uri uri,
    dynamic data,
    List<FileUpload> files,
    T Function(Map<String, dynamic>) fromJson, {
    Duration? timeout,
    void Function(int sent, int total)? onProgress,
    String? requestId,
  }) async {
    var totalBytes = 0;
    if (files.isEmpty) {
      throw ApiException(
        'No files to upload',
        errorData: {'statusCode': 400},
      );
    }

    // Calculate total size of files
    for (final file in files) {
      totalBytes += await file.file.length();
    }

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        ..._headers,
        if (requestId != null) 'X-Request-ID': requestId,
      })
      ..fields.addAll(_flattenMap(data));

    var sentBytes = 0;
    for (final file in files) {
      final stream = file.file.openRead();
      final length = await file.file.length();

      final Stream<List<int>> progressStream = onProgress == null
          ? stream
          : stream.transform(
              StreamTransformer<List<int>, List<int>>.fromHandlers(
                handleData: (List<int> data, EventSink<List<int>> sink) {
                  sentBytes += data.length;
                  onProgress(sentBytes, totalBytes);
                  sink.add(data);
                },
              ),
            );

      request.files.add(
        http.MultipartFile(
          file.field,
          progressStream,
          length,
          filename: path.basename(file.file.path),
          contentType: file.contentType,
        ),
      );
    }

    final streamedResponse = await _retryWithTimeout(
      () => request.send(),
      timeout: timeout ?? _defaultTimeout,
    );

    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response, fromJson);
  }

  Future<T> put<T>(
    String endpoint,
    dynamic data,
    T Function(Map<String, dynamic>) fromJson, {
    Duration? timeout,
    bool idempotent = true,
  }) async {
    final uri = Uri.parse(ApiConfig.baseUrl + endpoint);
    final requestId = _generateRequestId();

    // PUT requests are typically idempotent
    if (idempotent) {
      final lock = _requestLocks.putIfAbsent(endpoint, () => Lock());
      return lock.synchronized(() => _executePut(
        uri,
        data,
        fromJson,
        timeout: timeout,
        requestId: requestId,
      ));
    }

    return _executePut(
      uri,
      data,
      fromJson,
      timeout: timeout,
      requestId: requestId,
    );
  }

  Future<T> _executePut<T>(
    Uri uri,
    dynamic data,
    T Function(Map<String, dynamic>) fromJson, {
    Duration? timeout,
    String? requestId,
  }) async {
    try {
      await _checkConnectivity();

      final headers = {
        ..._headers,
        if (requestId != null) 'X-Request-ID': requestId,
      };

      final response = await _retryWithTimeout(
        () => _client.put(
          uri,
          headers: headers,
          body: jsonEncode(_sanitizeData(data)),
        ),
        timeout: timeout ?? _defaultTimeout,
      );

      return _handleResponse(response, fromJson);
    } catch (e) {
      _logger.error('PUT ${uri.path} failed', e);
      rethrow;
    }
  }

  Future<void> delete(
    String endpoint, {
    Duration? timeout,
    bool idempotent = true,
  }) async {
    final uri = Uri.parse(ApiConfig.baseUrl + endpoint);
    final requestId = _generateRequestId();

    // DELETE requests are typically idempotent
    if (idempotent) {
      final lock = _requestLocks.putIfAbsent(endpoint, () => Lock());
      return lock.synchronized(() => _executeDelete(
        uri,
        timeout: timeout,
        requestId: requestId,
      ));
    }

    return _executeDelete(
      uri,
      timeout: timeout,
      requestId: requestId,
    );
  }

  Future<void> _executeDelete(
    Uri uri, {
    Duration? timeout,
    String? requestId,
  }) async {
    try {
      await _checkConnectivity();

      final headers = {
        ..._headers,
        if (requestId != null) 'X-Request-ID': requestId,
      };

      final response = await _retryWithTimeout(
        () => _client.delete(uri, headers: headers),
        timeout: timeout ?? _defaultTimeout,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = _parseErrorResponse(response);
        throw ApiException(
          error['message'] ?? 'Delete operation failed',
          errorData: {'statusCode': response.statusCode, ...error},
        );
      }
    } catch (e) {
      _logger.error('DELETE ${uri.path} failed', e);
      rethrow;
    }
  }

  Future<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    _logger.debug(
      'Response ${response.statusCode} for ${response.request?.url}',
      response.body,
    );

    try {
      final data = _parseJsonResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return fromJson(data);
      }

      throw ApiException(
        data['message'] ?? _getDefaultErrorMessage(response.statusCode),
        errorData: {
          'statusCode': response.statusCode,
          ...data,
        },
      );
    } on FormatException catch (e) {
      _logger.error('Failed to parse response', e);
      throw ApiException(
        'Invalid response format',
        errorData: {
          'statusCode': response.statusCode,
          'body': response.body,
        },
      );
    }
  }

  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request';
      case 401:
        return 'Session expired, please login again';
      case 403:
        return 'You do not have permission to perform this action';
      case 404:
        return 'Resource not found';
      case 409:
        return 'A conflict occurred';
      case 422:
        return 'Validation failed';
      case 429:
        return 'Too many requests, please try again later';
      case 500:
        return 'Internal server error occurred';
      default:
        return 'Operation failed';
    }
  }

  Map<String, dynamic> _parseJsonResponse(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    } on FormatException {
      throw ApiException(
        'Invalid response format',
        errorData: {
          'statusCode': response.statusCode,
          'body': response.body,
        },
      );
    }
  }

  Future<List<T>> getList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParams,
    bool useCache = true,
    Duration? timeout,
    bool forceRefresh = false,
  }) async {
    try {
      await _checkConnectivity();

      final uri = Uri.parse(ApiConfig.baseUrl + endpoint).replace(
        queryParameters: queryParams?.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        ),
      );

      final cacheKey = '${uri.toString()}_${_token ?? 'no_auth'}';

      // Check cache if enabled and not forcing refresh
      if (useCache && !forceRefresh) {
        final cachedResponse = _cache[cacheKey];
        if (cachedResponse?.isValid(_cacheExpiry) ?? false) {
          _logger.debug('Cache hit for $endpoint');
          final List<dynamic> cachedList = cachedResponse!.data as List;
          return cachedList
              .map((item) => fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }

      final response = await _retryWithTimeout(
        () => _client.get(uri, headers: _headers),
        timeout: timeout ?? _defaultTimeout,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData is! List) {
          throw ApiException(
            'Expected list response',
            errorData: {
              'statusCode': response.statusCode,
              'data': responseData,
            },
          );
        }

        final result = responseData
            .map((item) => fromJson(item as Map<String, dynamic>))
            .toList();

        // Cache the response if caching is enabled
        if (useCache) {
          _manageCache();
          _cache[cacheKey] = CachedResponse(
            data: responseData,
            timestamp: DateTime.now(),
          );
        }

        return result;
      } 

      // If not 200, let _handleResponse process the error.
      // The fromJson function here is a placeholder and will not be executed
      // because _handleResponse throws for non-2xx status codes.
      return _handleResponse(response,
          (data) => throw StateError('This should not be reachable'));
    } on TimeoutException {
      throw ApiException(
        'Request timed out',
        errorData: {'statusCode': 408},
      );
    } on FormatException {
      throw ApiException(
        'Invalid response format',
        errorData: {'statusCode': 0},
      );
    } catch (e) {
      _logger.error('GET List $endpoint failed', e);
      rethrow;
    }
  }

  Future<T> patch<T>(
    String endpoint,
    dynamic data,
    T Function(Map<String, dynamic>) fromJson, {
    Duration? timeout,
    bool idempotent = false,
  }) async {
    final uri = Uri.parse(ApiConfig.baseUrl + endpoint);
    final requestId = _generateRequestId();

    if (idempotent) {
      final lock = _requestLocks.putIfAbsent(endpoint, () => Lock());
      return lock.synchronized(() => _executePatch(
        uri,
        data,
        fromJson,
        timeout: timeout,
        requestId: requestId,
      ));
    }

    return _executePatch(
      uri,
      data,
      fromJson,
      timeout: timeout,
      requestId: requestId,
    );
  }

  Future<T> _executePatch<T>(
    Uri uri,
    dynamic data,
    T Function(Map<String, dynamic>) fromJson, {
    Duration? timeout,
    String? requestId,
  }) async {
    try {
      await _checkConnectivity();

      final headers = {
        ..._headers,
        if (requestId != null) 'X-Request-ID': requestId,
      };

      final response = await _retryWithTimeout(
        () => _client.patch(
          uri,
          headers: headers,
          body: jsonEncode(_sanitizeData(data)),
        ),
        timeout: timeout ?? _defaultTimeout,
      );

      return _handleResponse(response, fromJson);
    } catch (e) {
      _logger.error('PATCH ${uri.path} failed', e);
      rethrow;
    }
  }

  Future<T> _retryWithTimeout<T>(
    Future<T> Function() operation, {
    required Duration timeout,
  }) async {
    var attempts = 0;
    Exception? lastError;

    while (attempts < _maxRetries) {
      try {
        return await operation().timeout(timeout);
      } catch (e) {
        attempts++;
        lastError = e is Exception ? e : Exception(e.toString());

        if (!_shouldRetry(e) || attempts >= _maxRetries) {
          break;
        }

        final delay = _retryDelay * attempts;
        _logger.debug(
          'Request failed (attempt $attempts), retrying in ${delay.inSeconds}s...',
          e,
        );
        await Future.delayed(delay);
      }
    }

    throw ApiException(
      'Request failed after $attempts attempts',
      errorData: {
        'lastError': lastError.toString(),
        'statusCode': _getStatusCodeFromError(lastError),
      },
    );
  }

  bool _shouldRetry(Object error) {
    return error is TimeoutException ||
           error is SocketException ||
           error is http.ClientException ||
           (error is ApiException && error.isRetryable);
  }

  int? _getStatusCodeFromError(Exception? error) {
    if (error is ApiException) {
      return error.statusCode;
    }
    if (error is TimeoutException) {
      return 408;
    }
    if (error is SocketException) {
      return 0;
    }
    return null;
  }

  Map<String, dynamic> _parseErrorResponse(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      return {
        'message': response.body,
        'statusCode': response.statusCode,
      };
    }
  }

  Future<void> _checkConnectivity() async {
    if (!await ConnectivityUtils.hasConnection()) {
      throw ApiException(
        'No internet connection',
        errorData: {'statusCode': 0},
      );
    }
  }

  void _manageCache() {
    if (_cache.length > _maxCacheSize) {
      // Remove oldest entries when cache is full
      final sortedEntries = _cache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      final entriesToRemove = sortedEntries.take((_maxCacheSize * 0.2).ceil());
      for (final entry in entriesToRemove) {
        _cache.remove(entry.key);
      }
    }
  }

  dynamic _sanitizeData(dynamic data) {
    if (data == null) return null;
    
    if (data is Map) {
      return Map.fromEntries(
        data.entries.where((e) => e.value != null).map(
          (e) => MapEntry(e.key, _sanitizeData(e.value)),
        ),
      );
    }
    
    if (data is List) {
      return data.map(_sanitizeData).toList();
    }
    
    if (data is DateTime) {
      return data.toIso8601String();
    }
    
    return data;
  }

  Map<String, String> _flattenMap(dynamic data, [String prefix = '']) {
    final result = <String, String>{};
    
    if (data is Map) {
      data.forEach((key, value) {
        final newKey = prefix.isEmpty ? key : '$prefix[$key]';
        if (value is Map || value is List) {
          result.addAll(_flattenMap(value, newKey));
        } else {
          result[newKey] = value?.toString() ?? '';
        }
      });
    } else if (data is List) {
      for (var i = 0; i < data.length; i++) {
        final value = data[i];
        final newKey = '$prefix[$i]';
        if (value is Map || value is List) {
          result.addAll(_flattenMap(value, newKey));
        } else {
          result[newKey] = value?.toString() ?? '';
        }
      }
    }
    
    return result;
  }

  void clearCache() {
    _cache.clear();
  }

  void dispose() {
    _client.close();
    clearCache();
    _requestLocks.clear();
  }
}

class CachedResponse {
  final dynamic data;
  final DateTime timestamp;

  CachedResponse({
    required this.data,
    required this.timestamp,
  });

  bool isValid(Duration expiry) {
    return DateTime.now().difference(timestamp) < expiry;
  }
}

class FileUpload {
  final String field;
  final File file;
  final MediaType? contentType;

  FileUpload._({
    required this.field,
    required this.file,
    this.contentType,
  });

  static Future<FileUpload> create({
    required String field,
    required File file,
    MediaType? contentType,
  }) async {
    if (!await file.exists()) {
      throw ApiException(
        'File not found: ${file.path}',
        errorData: {'statusCode': 400},
      );
    }

    if ((await file.length()) == 0) {
      throw ApiException(
        'File is empty: ${file.path}',
        errorData: {'statusCode': 400},
      );
    }

    return FileUpload._(
      field: field,
      file: file,
      contentType: contentType,
    );
  }
}

@visibleForTesting
@visibleForTesting
class Lock {
  Completer<void>? _completer;
  
  Lock();

  Future<T> synchronized<T>(Future<T> Function() func) async {
    while (_completer != null) {
      await _completer!.future;
    }

    _completer = Completer<void>();
    try {
      return await func();
    } finally {
      _completer!.complete();
      _completer = null;
    }
  }
}
