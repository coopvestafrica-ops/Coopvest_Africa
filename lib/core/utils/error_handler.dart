import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../exceptions/app_exceptions.dart';
import 'logger.dart';

/// Handles and converts various exceptions to AppException
class ErrorHandler {
  static AppException handleException(dynamic exception, [StackTrace? stackTrace]) {
    AppLogger.error('Exception caught', exception, stackTrace);

    if (exception is AppException) {
      return exception;
    }

    if (exception is FirebaseAuthException) {
      return _handleFirebaseAuthException(exception);
    }

    if (exception is DioException) {
      return _handleDioException(exception);
    }

    if (exception is SocketException) {
      return NetworkException(
        message: 'Network error: ${exception.message}',
        originalException: exception,
      );
    }

    return AppException(
      message: exception.toString(),
      code: 'UNKNOWN_ERROR',
      originalException: exception,
    );
  }

  static AuthException _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return UserNotFoundAuthException(originalException: e);
      case 'wrong-password':
        return InvalidCredentialsException(originalException: e);
      case 'invalid-email':
        return AuthException(
          message: 'Invalid email address',
          code: 'INVALID_EMAIL',
          originalException: e,
        );
      case 'user-disabled':
        return AuthException(
          message: 'User account has been disabled',
          code: 'USER_DISABLED',
          originalException: e,
        );
      case 'too-many-requests':
        return AuthException(
          message: 'Too many login attempts. Please try again later.',
          code: 'TOO_MANY_REQUESTS',
          originalException: e,
        );
      case 'operation-not-allowed':
        return AuthException(
          message: 'Operation not allowed',
          code: 'OPERATION_NOT_ALLOWED',
          originalException: e,
        );
      case 'email-already-in-use':
        return EmailAlreadyInUseException(originalException: e);
      case 'weak-password':
        return WeakPasswordException(originalException: e);
      case 'invalid-credential':
        return InvalidCredentialsException(originalException: e);
      case 'network-request-failed':
        return NetworkException(
          message: 'Network request failed',
          originalException: e,
        );
      default:
        return AuthException(
          message: e.message ?? 'Authentication error occurred',
          code: e.code,
          originalException: e,
        );
    }
  }

  static AppException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
          originalException: e,
        );
      case DioExceptionType.badResponse:
        return _handleHttpError(e.response?.statusCode ?? 0, e);
      case DioExceptionType.cancel:
        return AppException(
          message: 'Request cancelled',
          code: 'REQUEST_CANCELLED',
          originalException: e,
        );
      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return NetworkException(
            message: 'No internet connection',
            originalException: e,
          );
        }
        return AppException(
          message: 'An unknown error occurred',
          code: 'UNKNOWN_ERROR',
          originalException: e,
        );
      default:
        return NetworkException(
          message: 'Network error occurred',
          originalException: e,
        );
    }
  }

  static AppException _handleHttpError(int statusCode, DioException e) {
    switch (statusCode) {
      case 400:
        return AppException(
          message: 'Bad request',
          code: 'BAD_REQUEST',
          originalException: e,
        );
      case 401:
        return UnauthorizedException(originalException: e);
      case 403:
        return AppException(
          message: 'Access forbidden',
          code: 'FORBIDDEN',
          originalException: e,
        );
      case 404:
        return AppException(
          message: 'Resource not found',
          code: 'NOT_FOUND',
          originalException: e,
        );
      case 500:
      case 502:
      case 503:
        return ServerException(
          message: 'Server error. Please try again later.',
          statusCode: statusCode,
          originalException: e,
        );
      default:
        return ServerException(
          message: 'HTTP Error: $statusCode',
          statusCode: statusCode,
          originalException: e,
        );
    }
  }
}

// For socket exceptions
class SocketException implements Exception {
  final String message;

  SocketException(this.message);

  @override
  String toString() => message;
}
