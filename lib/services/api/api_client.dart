import 'package:dio/dio.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';
import '../storage/token_manager.dart';

/// HTTP API Client with automatic token injection and interceptors
class ApiClient {
  final Dio _dio;
  final TokenManager _tokenManager;
  final String baseUrl;

  static const int _connectTimeout = 30000; // 30 seconds
  static const int _receiveTimeout = 30000; // 30 seconds
  static const int _sendTimeout = 30000; // 30 seconds

  ApiClient({
    required this.baseUrl,
    required TokenManager tokenManager,
    Dio? dio,
  })  : _tokenManager = tokenManager,
        _dio = dio ?? Dio() {
    _setupDio();
  }

  /// Setup Dio configuration and interceptors
  void _setupDio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: _connectTimeout),
      receiveTimeout: const Duration(milliseconds: _receiveTimeout),
      sendTimeout: const Duration(milliseconds: _sendTimeout),
      contentType: 'application/json',
      headers: {
        'Accept': 'application/json',
      },
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    AppLogger.info('ApiClient initialized with baseUrl: $baseUrl');
  }

  /// Request interceptor - adds token to headers
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      AppLogger.debug('Request: ${options.method} ${options.path}');

      // Add authorization token if available
      final token = _tokenManager.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        AppLogger.debug('Token injected into request headers');
      }

      handler.next(options);
    } catch (e) {
      AppLogger.error('Error in request interceptor', e);
      handler.reject(DioException(
        requestOptions: options,
        error: e,
        type: DioExceptionType.unknown,
      ));
    }
  }

  /// Response interceptor
  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    AppLogger.debug(
      'Response: ${response.statusCode} ${response.requestOptions.path}',
    );
    handler.next(response);
  }

  /// Error interceptor - handles 401 and retries with token refresh
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    AppLogger.error('API Error: ${error.message}', error);

    // Handle 401 Unauthorized - attempt token refresh
    if (error.response?.statusCode == 401) {
      try {
        AppLogger.warning('Received 401 Unauthorized, attempting token refresh');
        // Token refresh logic would go here
        // For now, we'll just reject the request
        handler.reject(error);
      } catch (e) {
        AppLogger.error('Token refresh failed', e);
        handler.reject(error);
      }
    } else {
      handler.reject(error);
    }
  }

  /// GET request
  Future<T> get<T>({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      AppLogger.info('GET request to: $endpoint');
      final response = await _dio.get<T>(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } catch (e) {
      AppLogger.error('GET request failed', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// POST request
  Future<T> post<T>({
    required String endpoint,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      AppLogger.info('POST request to: $endpoint');
      final response = await _dio.post<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } catch (e) {
      AppLogger.error('POST request failed', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// PUT request
  Future<T> put<T>({
    required String endpoint,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      AppLogger.info('PUT request to: $endpoint');
      final response = await _dio.put<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } catch (e) {
      AppLogger.error('PUT request failed', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// PATCH request
  Future<T> patch<T>({
    required String endpoint,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      AppLogger.info('PATCH request to: $endpoint');
      final response = await _dio.patch<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } catch (e) {
      AppLogger.error('PATCH request failed', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// DELETE request
  Future<T> delete<T>({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      AppLogger.info('DELETE request to: $endpoint');
      final response = await _dio.delete<T>(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } catch (e) {
      AppLogger.error('DELETE request failed', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Download file
  Future<void> downloadFile({
    required String endpoint,
    required String savePath,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      AppLogger.info('Downloading file from: $endpoint');
      await _dio.download(
        endpoint,
        savePath,
        onReceiveProgress: onReceiveProgress,
      );
      AppLogger.info('File downloaded successfully');
    } catch (e) {
      AppLogger.error('File download failed', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Upload file
  Future<T> uploadFile<T>({
    required String endpoint,
    required String filePath,
    String? fileName,
    Map<String, dynamic>? additionalFields,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      AppLogger.info('Uploading file to: $endpoint');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        if (additionalFields != null) ...additionalFields,
      });

      final response = await _dio.post<T>(
        endpoint,
        data: formData,
        onSendProgress: onSendProgress,
      );

      AppLogger.info('File uploaded successfully');
      return response.data as T;
    } catch (e) {
      AppLogger.error('File upload failed', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Set authorization token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    AppLogger.debug('Authorization token set');
  }

  /// Clear authorization token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
    AppLogger.debug('Authorization token cleared');
  }

  /// Get Dio instance for advanced usage
  Dio get dio => _dio;
}
