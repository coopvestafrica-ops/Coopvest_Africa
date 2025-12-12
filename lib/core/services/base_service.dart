import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' show pow;
import 'package:http/http.dart' as http;
import '../exceptions/api_exception.dart';
import '../exceptions/network_exception.dart';
import '../models/api_event.dart';
import '../utils/cancellation_token.dart';
import '../utils/connectivity_checker.dart';

/// Base service class providing common functionality for API services.
/// Features:
/// - Automatic retry with exponential backoff
/// - Response caching
/// - Rate limiting
/// - Request cancellation
/// - API versioning
/// - Request timeouts
/// - Event streaming
/// - Logging
/// - Connectivity checking
abstract class BaseService {
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration defaultRetryInterval = Duration(seconds: 2);
  static const int maxRetryAttempts = 3;
  static const Duration rateLimitInterval = Duration(minutes: 1);
  static const int maxRequestsPerInterval = 60;
  static const Duration maxBackoffDelay = Duration(minutes: 1);

  final http.Client _client;
  final ConnectivityChecker _connectivityChecker;
  final Map<String, _CachedResponse> _cache = {};
  final Map<String, List<DateTime>> _rateLimiter = {};
  final StreamController<ApiEvent> _eventController = StreamController<ApiEvent>.broadcast();

  /// Stream of API events for monitoring requests
  Stream<ApiEvent> get events => _eventController.stream;

  BaseService({
    http.Client? client,
    ConnectivityChecker? connectivityChecker,
  }) : 
    _client = client ?? http.Client(),
    _connectivityChecker = connectivityChecker ?? ConnectivityChecker();

  http.Client get client => _client;

  /// Makes a HTTP GET request with error handling, retries, and caching
  Future<T> get<T>({
    required String path,
    required T Function(Map<String, dynamic> json) parser,
    String? token,
    Duration? cacheDuration,
    Duration? timeout,
    Map<String, String>? queryParams,
    bool forceRefresh = false,
    bool useCache = true,
    CancellationToken? cancellationToken,
  }) async {
    return _executeRequest<T>(
      method: 'GET',
      path: path,
      parser: parser,
      token: token,
      cacheDuration: cacheDuration,
      timeout: timeout,
      queryParams: queryParams,
      forceRefresh: forceRefresh,
      useCache: useCache,
      cancellationToken: cancellationToken,
    );
  }

  /// Makes a HTTP POST request with error handling and retries
  Future<T> post<T>({
    required String path,
    required T Function(Map<String, dynamic> json) parser,
    Object? body,
    String? token,
    Duration? timeout,
    Map<String, String>? queryParams,
    CancellationToken? cancellationToken,
  }) async {
    return _executeRequest<T>(
      method: 'POST',
      path: path,
      parser: parser,
      body: body,
      token: token,
      timeout: timeout,
      queryParams: queryParams,
      useCache: false,
      cancellationToken: cancellationToken,
    );
  }

  /// Makes a HTTP PUT request with error handling and retries
  Future<T> put<T>({
    required String path,
    required T Function(Map<String, dynamic> json) parser,
    Object? body,
    String? token,
    Duration? timeout,
    Map<String, String>? queryParams,
    CancellationToken? cancellationToken,
  }) async {
    return _executeRequest<T>(
      method: 'PUT',
      path: path,
      parser: parser,
      body: body,
      token: token,
      timeout: timeout,
      queryParams: queryParams,
      useCache: false,
      cancellationToken: cancellationToken,
    );
  }

  /// Makes a HTTP PATCH request with error handling and retries  
  Future<T> patch<T>({
    required String path,
    required T Function(Map<String, dynamic> json) parser,
    Object? body,
    String? token,
    Duration? timeout,
    Map<String, String>? queryParams,
    CancellationToken? cancellationToken,
  }) async {
    return _executeRequest<T>(
      method: 'PATCH',
      path: path,
      parser: parser,
      body: body,
      token: token,
      timeout: timeout,
      queryParams: queryParams,
      useCache: false,
      cancellationToken: cancellationToken,
    );
  }

  /// Makes a HTTP DELETE request with error handling and retries
  Future<T> delete<T>({
    required String path,
    required T Function(Map<String, dynamic> json) parser,
    String? token,
    Duration? timeout,
    Map<String, String>? queryParams,
    CancellationToken? cancellationToken,
  }) async {
    return _executeRequest<T>(
      method: 'DELETE',
      path: path,
      parser: parser,
      token: token,
      timeout: timeout,
      queryParams: queryParams,
      useCache: false,
      cancellationToken: cancellationToken,
    );
  }

  /// Generic request execution with full error handling, retries, caching etc.
  Future<T> _executeRequest<T>({
    required String method,
    required String path,
    required T Function(Map<String, dynamic> json) parser,
    Object? body,
    String? token,
    Duration? cacheDuration,
    Duration? timeout,
    Map<String, String>? queryParams,
    bool forceRefresh = false,
    bool useCache = false,
    CancellationToken? cancellationToken,
  }) async {
    timeout ??= defaultTimeout;
    final startTime = DateTime.now();
    
    try {
      // Check for cancellation
      if (cancellationToken?.isCancelled ?? false) {
        throw ApiException(
          'Request cancelled by user',
          errorData: {'statusCode': 499, 'cancelled': true},
        );
      }

      // Check connectivity first
      if (!await _connectivityChecker.hasConnection) {
        final exception = NetworkException(
          'No internet connection',
          retryAfter: defaultRetryInterval,
        );
        
        _eventController.add(RequestFailed(
          method: method,
          path: path,
          error: exception.toString(),
          duration: DateTime.now().difference(startTime),
          willRetry: true,
        ));
        
        throw exception;
      }

      // Emit request started event
      _eventController.add(RequestStarted(
        method: method,
        path: path,
        body: body as Map<String, dynamic>?,
      ));

      // Apply rate limiting
      final rateLimitKey = '${method}_$path';
      if (!_checkRateLimit(rateLimitKey)) {
        final resetAfter = _getRateLimitReset();
        _eventController.add(RateLimitExceeded(
          method: method,
          path: path,
          resetAfter: resetAfter,
        ));
        throw ApiException(
          'Rate limit exceeded',
          errorData: {'statusCode': 429},
          retryAfter: resetAfter,
        );
      }

      // Build URL with query parameters
      var uri = Uri.parse(path);
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      // Check cache for GET requests
      final cacheKey = uri.toString();
      if (method == 'GET' && useCache && !forceRefresh) {
        final cached = _getFromCache(cacheKey);
        if (cached != null) {
          try {
            final age = DateTime.now().difference(cached.timestamp);
            _eventController.add(CacheHit(path: cacheKey, age: age));
            _logApiEvent(CacheHit(path: cacheKey, age: age));
            return parser(cached.data);
          } catch (e) {
            developer.log(
              'Cache parse error: $e',
              name: 'BaseService',
              error: e,
            );
          }
        }
      }

      // Execute request with exponential backoff retries
      int attempt = 0;
      ApiException? lastError;

      while (attempt < maxRetryAttempts) {
        try {
          // Check for cancellation before each attempt
          if (cancellationToken?.isCancelled ?? false) {
            throw ApiException(
              'Request cancelled by user',
              errorData: {'statusCode': 499, 'cancelled': true},
            );
          }

          final response = await _executeWithTimeout(
            () => _makeRequest(
              method: method,
              uri: uri,
              body: body,
              token: token,
            ),
            timeout: timeout,
            cancellationToken: cancellationToken,
          );

          final statusCode = response.statusCode;
          final responseBody = _parseResponseBody(response);
          final transformedBody = _transformResponse(responseBody);
          
          final success = transformedBody['success'] as bool? ?? 
            statusCode >= 200 && statusCode < 300;

          if (success) {
            _eventController.add(RequestCompleted(
              method: method,
              path: path,
              statusCode: statusCode,
              duration: DateTime.now().difference(startTime),
            ));
            _logApiEvent(RequestCompleted(
              method: method,
              path: path,
              statusCode: statusCode,
              duration: DateTime.now().difference(startTime),
            ));

            // Cache successful GET responses
            if (method == 'GET' && useCache) {
              _cache[cacheKey] = _CachedResponse(
                data: transformedBody,
                timestamp: DateTime.now(),
                duration: cacheDuration ?? const Duration(minutes: 5),
              );
            }

            return parser(transformedBody);
          } else {
            final errorData = Map<String, dynamic>.from(responseBody);
            errorData['statusCode'] = statusCode;

            throw ApiException(
              errorData['message'] as String? ?? 'Unknown error occurred',
              errorData: errorData,
              retryAfter: _getRetryAfterFromHeaders(response.headers),
            );
          }
        } on TimeoutException {
          lastError = ApiException(
            'Request timed out',
            errorData: {'statusCode': 408},
            retryAfter: defaultRetryInterval,
          );
          _eventController.add(RequestFailed(
            method: method,
            path: path,
            error: 'Request timed out',
            statusCode: 408,
            duration: DateTime.now().difference(startTime),
            willRetry: attempt < maxRetryAttempts - 1,
          ));
        } on ApiException catch (e) {
          lastError = e;
          _eventController.add(RequestFailed(
            method: method,
            path: path,
            error: e.message,
            statusCode: e.statusCode,
            duration: DateTime.now().difference(startTime),
            willRetry: e.isRetryable && attempt < maxRetryAttempts - 1,
          ));
          if (!e.isRetryable) break;
        } catch (e) {
          lastError = ApiException(
            'Unknown error occurred: $e',
            errorData: {'statusCode': 500},
            retryAfter: defaultRetryInterval,
          );
          _eventController.add(RequestFailed(
            method: method,
            path: path,
            error: 'Unknown error occurred: $e',
            statusCode: 500,
            duration: DateTime.now().difference(startTime),
            willRetry: attempt < maxRetryAttempts - 1,
          ));
        }

        attempt++;
        if (attempt < maxRetryAttempts) {
          final retryAfter = lastError.retryAfter ?? _calculateBackoffDelay(attempt);
          await Future.delayed(retryAfter);
        }
      }

      throw lastError ?? ApiException(
        'All retry attempts failed',
        errorData: {'statusCode': 500},
      );
    } catch (e) {
      developer.log(
        'Request failed: $e',
        name: 'BaseService',
        error: e,
      );
      rethrow;
    }
  }

  /// Makes the actual HTTP request
  Future<http.Response> _makeRequest({
    required String method,
    required Uri uri,
    Object? body,
    String? token,
  }) {
    final headers = _getHeaders(token);
    
    switch (method) {
      case 'GET':
        return _client.get(uri, headers: headers);
      case 'POST':
        return _client.post(uri, headers: headers, body: jsonEncode(body));
      case 'PUT':
        return _client.put(uri, headers: headers, body: jsonEncode(body));
      case 'PATCH':
        return _client.patch(uri, headers: headers, body: jsonEncode(body));
      case 'DELETE':
        return _client.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  /// Execute a request with a timeout and cancellation support
  Future<T> _executeWithTimeout<T>(
    Future<T> Function() action, {
    required Duration timeout,
    CancellationToken? cancellationToken,
  }) async {
    if (cancellationToken?.isCancelled ?? false) {
      throw ApiException(
        'Request cancelled by user',
        errorData: {'statusCode': 499, 'cancelled': true},
      );
    }

    final completer = Completer<T>();
    
    cancellationToken?.addListener(() {
      if (!completer.isCompleted && cancellationToken.isCancelled) {
        completer.completeError(ApiException(
          'Request cancelled by user',
          errorData: {'statusCode': 499, 'cancelled': true},
        ));
      }
    });

    try {
      final result = await action().timeout(timeout);
      if (!completer.isCompleted) completer.complete(result);
    } catch (e) {
      if (!completer.isCompleted) completer.completeError(e);
    }

    return completer.future;
  }

  /// Get headers for the request
  Map<String, String> _getHeaders([String? token]) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-api-version': '1.0',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Parse response body handling different content types
  Map<String, dynamic> _parseResponseBody(http.Response response) {
    final contentType = response.headers['content-type'];
    final body = response.body;

    if (contentType?.contains('application/json') ?? false) {
      if (body.isEmpty) return {};
      return jsonDecode(body) as Map<String, dynamic>;
    } else {
      throw ApiException(
        'Unsupported content type: $contentType',
        errorData: {'statusCode': response.statusCode},
      );
    }
  }

  /// Transform response before parsing
  Map<String, dynamic> _transformResponse(Map<String, dynamic> response) {
    // Add any common response transformations here
    // For example, standardizing date formats, unwrapping data objects, etc.
    return response;
  }

  /// Get retry delay from response headers
  Duration _getRetryAfterFromHeaders(Map<String, String> headers) {
    final retryAfter = headers['retry-after'];
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null) {
        return Duration(seconds: seconds);
      }
    }
    return defaultRetryInterval;
  }

  /// Calculate exponential backoff delay
  Duration _calculateBackoffDelay(int attempt) {
    if (attempt <= 0) return Duration.zero;
    final delay = Duration(milliseconds: (pow(2, attempt) * 1000).toInt());
    return delay > maxBackoffDelay ? maxBackoffDelay : delay;
  }

  /// Check if request is within rate limits
  bool _checkRateLimit(String key) {
    final now = DateTime.now();
    final times = _rateLimiter[key] ?? [];

    // Remove old timestamps
    times.removeWhere(
      (time) => now.difference(time) > rateLimitInterval
    );

    if (times.length >= maxRequestsPerInterval) {
      return false;
    }

    times.add(now);
    _rateLimiter[key] = times;
    return true;
  }

  /// Calculate when rate limit will reset
  Duration _getRateLimitReset() {
    final now = DateTime.now();
    final oldestAllowed = now.subtract(rateLimitInterval);
    
    for (final times in _rateLimiter.values) {
      times.sort();
      if (times.isNotEmpty && times.first.isAfter(oldestAllowed)) {
        return times.first.difference(oldestAllowed);
      }
    }

    return Duration.zero;
  }

  /// Get cached response if still valid
  _CachedResponse? _getFromCache(String key) {
    final cached = _cache[key];
    if (cached != null) {
      if (DateTime.now().difference(cached.timestamp) < cached.duration) {
        return cached;
      }
      _cache.remove(key); // Remove expired cache entry
    }
    return null;
  }

  /// Log API events with proper error handling
  void _logApiEvent(ApiEvent event) {
    try {
      developer.log(
        'API Event: ${event.runtimeType}',
        name: 'BaseService',
        error: event is RequestFailed ? event.error : null,
      );
    } catch (e) {
      // Prevent logging errors from affecting the main flow
      developer.log(
        'Error logging API event: $e',
        name: 'BaseService',
        level: 2000,
      );
    }
  }

  /// Clear all cached responses
  void clearCache() {
    _cache.clear();
  }

  /// Clean up resources
  void dispose() {
    _client.close();
    clearCache();
    _rateLimiter.clear();
    _eventController.close();
  }
}

/// Helper class for caching responses
class _CachedResponse {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final Duration duration;

  _CachedResponse({
    required this.data,
    required this.timestamp, 
    required this.duration,
  });
}
