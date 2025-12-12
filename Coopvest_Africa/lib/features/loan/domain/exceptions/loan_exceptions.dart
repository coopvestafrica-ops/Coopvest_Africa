/// Base exception class for all loan-related exceptions
abstract class LoanException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const LoanException(this.message, {this.code, this.originalError});

  @override
  String toString() {
    final base = code != null ? '$code: $message' : message;
    if (originalError != null) {
      return '$base (Caused by: $originalError)';
    }
    return base;
  }
}

/// Exception thrown when loan rollover operations fail
class LoanRolloverException extends LoanException {
  const LoanRolloverException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Thrown when loan-related validation fails
class ValidationException extends LoanException {
  const ValidationException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Thrown when a loan or related entity is not found
class NotFoundException extends LoanException {
  const NotFoundException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Thrown when network operations fail
class NetworkException extends LoanException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Thrown when user authentication is required or invalid
class AuthException extends LoanException {
  const AuthException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Thrown when a loan operation fails eligibility checks
class EligibilityException extends LoanException {
  /// Additional requirements or criteria that were not met
  final Map<String, dynamic>? requirements;

  const EligibilityException(
    super.message, {
    this.requirements,
    super.code,
    super.originalError,
  });

  @override
  String toString() {
    final base = super.toString();
    if (requirements != null) {
      return '$base\nRequirements: $requirements';
    }
    return base;
  }
}
