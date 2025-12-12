/// Base exception class for all API errors
class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? errorData;
  final Duration? retryAfter;

  ApiException(
    this.message, {
    this.errorData,
    this.retryAfter,
  });

  @override
  String toString() => 'ApiException: $message${errorData != null ? ' ($errorData)' : ''}';

  /// Extract status code from error data if available
  int? get statusCode => errorData?['statusCode'] as int?;
  
  /// Extract error code from error data if available
  String? get errorCode => errorData?['code'] as String?;

  /// Whether this error can be retried
  bool get isRetryable {
    final status = statusCode;
    if (status == null) return false;
    
    return status == 408 || // Request Timeout
           status == 429 || // Too Many Requests
           status >= 500;   // Server Errors
  }

  /// Whether this was a client error
  bool get isClientError {
    final status = statusCode;
    if (status == null) return false;
    return status >= 400 && status < 500;
  }

  /// Whether this was a server error  
  bool get isServerError {
    final status = statusCode;
    if (status == null) return false;
    return status >= 500;
  }

  /// Whether this was an authentication error
  bool get isAuthError {
    final status = statusCode;
    if (status == null) return false;
    return status == 401;
  }

  /// Whether this was a permission error
  bool get isPermissionError {
    final status = statusCode;
    if (status == null) return false;
    return status == 403;
  }

  /// Whether this was a not found error  
  bool get isNotFoundError {
    final status = statusCode;
    if (status == null) return false;
    return status == 404;
  }

  /// Whether this was a validation error
  bool get isValidationError {
    final status = statusCode;
    if (status == null) return false;
    return status == 422;
  }

  /// Whether this was a rate limit error
  bool get isRateLimitError {
    final status = statusCode;
    if (status == null) return false;
    return status == 429;
  }

  /// Whether this error has an associated rate limit
  bool get hasRateLimit => retryAfter != null;
}
