/// Custom exceptions for the application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  AppException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() => message;
}

/// Authentication related exceptions
class AuthException extends AppException {
  AuthException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
    message: message,
    code: code,
    originalException: originalException,
  );
}

class InvalidCredentialsException extends AuthException {
  InvalidCredentialsException({
    String message = 'Invalid email or password',
    dynamic originalException,
  }) : super(
    message: message,
    code: 'INVALID_CREDENTIALS',
    originalException: originalException,
  );
}

class UserNotFoundAuthException extends AuthException {
  UserNotFoundAuthException({
    String message = 'User not found',
    dynamic originalException,
  }) : super(
    message: message,
    code: 'USER_NOT_FOUND',
    originalException: originalException,
  );
}

class WeakPasswordException extends AuthException {
  WeakPasswordException({
    String message = 'Password is too weak',
    dynamic originalException,
  }) : super(
    message: message,
    code: 'WEAK_PASSWORD',
    originalException: originalException,
  );
}

class EmailAlreadyInUseException extends AuthException {
  EmailAlreadyInUseException({
    String message = 'Email is already in use',
    dynamic originalException,
  }) : super(
    message: message,
    code: 'EMAIL_ALREADY_IN_USE',
    originalException: originalException,
  );
}

class NetworkException extends AppException {
  NetworkException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
    message: message,
    code: code ?? 'NETWORK_ERROR',
    originalException: originalException,
  );
}

class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required String message,
    this.statusCode,
    String? code,
    dynamic originalException,
  }) : super(
    message: message,
    code: code ?? 'SERVER_ERROR',
    originalException: originalException,
  );
}

class TokenException extends AppException {
  TokenException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
    message: message,
    code: code ?? 'TOKEN_ERROR',
    originalException: originalException,
  );
}

class UnauthorizedException extends AppException {
  UnauthorizedException({
    String message = 'Unauthorized access',
    dynamic originalException,
  }) : super(
    message: message,
    code: 'UNAUTHORIZED',
    originalException: originalException,
  );
}

class CacheException extends AppException {
  CacheException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
    message: message,
    code: code ?? 'CACHE_ERROR',
    originalException: originalException,
  );
}
