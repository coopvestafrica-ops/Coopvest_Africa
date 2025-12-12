import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/connectivity_checker.dart';
import 'api_response.dart';

/// Helper class for making HTTP requests with proper error handling and retry logic
class ApiRequest {
  final String url;
  final String method;
  final Map<String, String>? headers;
  final Map<String, dynamic>? body;
  final Duration timeout;
  final int maxRetries;
  final bool requiresAuth;
  final ConnectivityChecker connectivityChecker;

  static const Duration defaultTimeout = Duration(seconds: 30);
  static const int defaultMaxRetries = 3;

  ApiRequest({
    required this.url,
    required this.method,
    required this.connectivityChecker,
    this.headers,
    this.body,
    this.timeout = defaultTimeout,
    this.maxRetries = defaultMaxRetries,
    this.requiresAuth = true,
  });

  Future<ApiResponse<T>> execute<T>({
    required T Function(dynamic) responseConverter,
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        // Check connectivity first
        if (!await connectivityChecker.hasConnection) {
          return ApiError(
            message: ApiErrorType.network.message,
            errorCode: ApiErrorType.network.code,
          );
        }

        // Make the request
        final response = await _makeRequest().timeout(timeout);

        // Handle the response
        return _handleResponse(response, responseConverter);
      } on TimeoutException {
        attempts++;
        if (attempts >= maxRetries) {
          return ApiError(
            message: ApiErrorType.timeout.message,
            errorCode: ApiErrorType.timeout.code,
          );
        }
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(milliseconds: 1000 * attempts));
      } catch (e) {
        return ApiError(
          message: e.toString(),
          errorCode: ApiErrorType.unknown.code,
        );
      }
    }

    return ApiError(
      message: 'Maximum retry attempts reached',
      errorCode: ApiErrorType.unknown.code,
    );
  }

  Future<http.Response> _makeRequest() async {
    final uri = Uri.parse(url);
    final requestHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    final encodedBody = body != null ? json.encode(body) : null;

    switch (method.toUpperCase()) {
      case 'GET':
        return http.get(uri, headers: requestHeaders);
      case 'POST':
        return http.post(
          uri,
          headers: requestHeaders,
          body: encodedBody,
        );
      case 'PUT':
        return http.put(
          uri,
          headers: requestHeaders,
          body: encodedBody,
        );
      case 'PATCH':
        return http.patch(
          uri,
          headers: requestHeaders,
          body: encodedBody,
        );
      case 'DELETE':
        return http.delete(uri, headers: requestHeaders);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic) responseConverter,
  ) {
    try {
      // Handle empty responses
      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return ApiSuccess<T>(
            data: responseConverter({}),
            message: 'Success',
          );
        } else {
          return ApiError(
            message: 'Empty response with status code: ${response.statusCode}',
            errorCode: ApiErrorType.unknown.code,
          );
        }
      }

      // Parse response body
      dynamic responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Try to convert raw response if successful
          return ApiSuccess<T>(
            data: responseConverter(response.body),
            message: 'Success',
          );
        } else {
          return ApiError(
            message: 'Invalid JSON response: ${response.body}',
            errorCode: ApiErrorType.unknown.code,
          );
        }
      }

      // Handle successful responses
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          return ApiSuccess(
            data: responseConverter(responseData),
            message: responseData is Map ? responseData['message'] as String? : null,
          );
        } catch (e) {
          return ApiError(
            message: 'Failed to convert response data: ${e.toString()}',
            errorCode: ApiErrorType.unknown.code,
          );
        }
      }

      // Handle error responses
      final String? message = responseData is Map ? responseData['message'] as String? : null;
      final dynamic errors = responseData is Map ? responseData['errors'] : null;

      switch (response.statusCode) {
        case 401:
          return ApiError(
            message: message ?? 'Session expired',
            errorCode: 'AUTH_EXPIRED',
          );
        case 403:
          return ApiError(
            message: message ?? 'Access denied',
            errorCode: 'AUTH_FORBIDDEN',
          );
        case 404:
          return ApiError(
            message: message ?? 'Resource not found',
            errorCode: 'NOT_FOUND',
          );
        case 422:
          return ApiError(
            message: message ?? 'Validation failed',
            errorCode: 'VALIDATION_ERROR',
            data: errors,
          );
        case 429:
          return ApiError(
            message: message ?? 'Too many requests',
            errorCode: 'RATE_LIMITED',
          );
        case 500:
          return ApiError(
            message: message ?? 'Internal server error',
            errorCode: 'SERVER_ERROR',
          );
        case 502:
        case 503:
        case 504:
          return ApiError(
            message: message ?? 'Service unavailable',
            errorCode: 'SERVICE_UNAVAILABLE',
          );
        default:
          return ApiError(
            message: message ?? 'Request failed with status: ${response.statusCode}',
            errorCode: 'HTTP_${response.statusCode}',
          );
      }
    } catch (e) {
      return ApiError(
        message: 'Failed to handle response: ${e.toString()}',
        errorCode: ApiErrorType.unknown.code,
      );
    }
  }
}
