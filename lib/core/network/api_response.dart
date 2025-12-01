import 'package:equatable/equatable.dart';

/// Base class for all API response models
class ApiResponse<T> extends Equatable {
  final bool success;
  final String? message;
  final T? data;
  final String? errorCode;
  final DateTime timestamp;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errorCode,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [success, message, data, errorCode, timestamp];

  Map<String, dynamic> toJson() {
    final json = {
      'success': success,
      'timestamp': timestamp.toIso8601String(),
    };

    if (message != null) json['message'] = message as Object;
    if (errorCode != null) json['errorCode'] = errorCode as Object;
    if (data != null) {
      json['data'] =
          data is Map || data is List ? data as Object : data.toString();
    }

    return json;
  }
}

/// API response for successful operations
class ApiSuccess<T> extends ApiResponse<T> {
  ApiSuccess({
    required T super.data,
    super.message,
    super.timestamp,
  }) : super(
          success: true,
        );

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['data'] = data is Map || data is List ? data : data.toString();
    return json;
  }
}

/// API response for failed operations
class ApiError<T> extends ApiResponse<T> {
  final StackTrace? stackTrace;

  ApiError({
    required super.message,
    super.errorCode,
    super.data,
    super.timestamp,
    this.stackTrace,
  }) : super(success: false);

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      };
}

/// Types of API errors
enum ApiErrorType {
  network,
  auth,
  authExpired,
  authForbidden,
  notFound,
  server,
  serverUnavailable,
  timeout,
  validation,
  rateLimited,
  unknown;

  String get message {
    switch (this) {
      case ApiErrorType.network:
        return 'Network connection error';
      case ApiErrorType.auth:
        return 'Authentication error';
      case ApiErrorType.authExpired:
        return 'Session expired';
      case ApiErrorType.authForbidden:
        return 'Access denied';
      case ApiErrorType.notFound:
        return 'Resource not found';
      case ApiErrorType.server:
        return 'Internal server error';
      case ApiErrorType.serverUnavailable:
        return 'Service unavailable';
      case ApiErrorType.timeout:
        return 'Request timed out';
      case ApiErrorType.validation:
        return 'Validation error';
      case ApiErrorType.rateLimited:
        return 'Too many requests';
      case ApiErrorType.unknown:
        return 'Unknown error';
    }
  }

  String get code {
    switch (this) {
      case ApiErrorType.network:
        return 'NETWORK_ERROR';
      case ApiErrorType.auth:
        return 'AUTH_ERROR';
      case ApiErrorType.authExpired:
        return 'AUTH_EXPIRED';
      case ApiErrorType.authForbidden:
        return 'AUTH_FORBIDDEN';
      case ApiErrorType.notFound:
        return 'NOT_FOUND';
      case ApiErrorType.server:
        return 'SERVER_ERROR';
      case ApiErrorType.serverUnavailable:
        return 'SERVICE_UNAVAILABLE';
      case ApiErrorType.timeout:
        return 'REQUEST_TIMEOUT';
      case ApiErrorType.validation:
        return 'VALIDATION_ERROR';
      case ApiErrorType.rateLimited:
        return 'RATE_LIMITED';
      case ApiErrorType.unknown:
        return 'UNKNOWN_ERROR';
    }
  }
}
