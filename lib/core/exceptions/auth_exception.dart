import '../exceptions/api_exception.dart';

/// Exception thrown for authentication-related errors in the application.
/// Extends [ApiException] to maintain consistent error handling across the app.
class AuthException extends ApiException {
  final AuthErrorType type;

  AuthException(
    super.message, {
    this.type = AuthErrorType.unknown,
    super.errorData,
    super.retryAfter,
  });

  /// Whether this error requires user to reauthenticate
  bool get requiresReauth => type == AuthErrorType.invalidSession ||
                         type == AuthErrorType.sessionExpired ||
                         type == AuthErrorType.tokenRevoked ||
                         type == AuthErrorType.invalidToken ||
                         type == AuthErrorType.refreshTokenFailed ||
                         type == AuthErrorType.passwordExpired;

  /// Whether this is a temporary error that can be retried
  @override
  bool get isRetryable => type == AuthErrorType.networkError ||
                      type == AuthErrorType.serverError ||
                      type == AuthErrorType.serviceUnavailable ||
                      type == AuthErrorType.maintenanceMode ||
                      super.isRetryable;

  /// Whether this is a security-related error  
  bool get isSecurityError => type == AuthErrorType.securityAlert ||
                          type == AuthErrorType.suspiciousActivity ||
                          type == AuthErrorType.ipBlocked ||
                          type == AuthErrorType.deviceNotTrusted ||
                          type == AuthErrorType.biometricsLockout;
                          
  /// Whether this error is related to account status
  bool get isAccountError => type == AuthErrorType.accountLocked ||
                         type == AuthErrorType.accountDisabled ||
                         type == AuthErrorType.accountDeleted ||
                         type == AuthErrorType.accountNotVerified;
                         
  /// Whether this error is related to MFA
  bool get isMfaError => type == AuthErrorType.mfaRequired ||
                     type == AuthErrorType.mfaFailed ||
                     type == AuthErrorType.mfaCodeExpired ||
                     type == AuthErrorType.mfaNotConfigured;
                     
  /// Whether this error is related to input validation
  @override
  bool get isValidationError => type == AuthErrorType.validationError ||
                           type == AuthErrorType.invalidEmail ||
                           type == AuthErrorType.invalidPassword ||
                           type == AuthErrorType.invalidUsername ||
                           type == AuthErrorType.invalidPhoneNumber;

  @override
  String toString() => 'AuthException: $message (Type: $type)${errorData != null ? ' ($errorData)' : ''}';
}

/// Types of authentication errors that can occur in the application.
/// Used to categorize authentication errors for proper handling and user feedback.
enum AuthErrorType {
  // Login/Session Related
  invalidCredentials,     // Wrong username/password
  invalidSession,        // Session is no longer valid
  sessionExpired,        // Session has timed out
  tokenRevoked,          // Token was explicitly revoked
  invalidToken,          // Invalid token format or signature
  refreshTokenFailed,    // Failed to refresh access token
  
  // Account Status Related
  accountLocked,         // Account is temporarily locked
  accountDisabled,       // Account is permanently disabled
  accountNotVerified,    // Email/Phone not verified
  accountDeleted,        // Account has been deleted
  
  // Rate Limiting/Security
  tooManyAttempts,       // Rate limit exceeded
  networkError,          // Network connectivity issues
  serverError,           // Server-side error
  securityAlert,         // Security-related issue detected
  suspiciousActivity,    // Suspicious activity detected
  ipBlocked,            // IP address is blocked
  regionBlocked,        // User's region is not allowed
  
  // Multi-Factor Authentication
  mfaRequired,           // Multi-factor auth required
  mfaFailed,            // Multi-factor auth failed
  mfaCodeExpired,       // MFA verification code expired
  mfaNotConfigured,     // MFA not set up for account
  
  // Biometric Authentication
  biometricsNotAvailable, // Device doesn't support biometrics
  biometricsFailed,      // Biometric authentication failed
  biometricsLockout,     // Too many failed biometric attempts
  
  // Registration/Profile
  registrationError,     // Generic registration error
  validationError,       // Input validation failed
  emailAlreadyExists,    // Email already registered
  usernameAlreadyExists, // Username already taken
  phoneAlreadyExists,    // Phone number already registered
  
  // Input Validation
  invalidPassword,       // Password doesn't meet requirements
  invalidEmail,         // Email format is invalid
  invalidUsername,      // Username format is invalid
  invalidPhoneNumber,   // Phone number format is invalid
  
  // Service Status
  serviceUnavailable,    // Service temporarily unavailable
  maintenanceMode,      // System under maintenance
  versionUnsupported,   // App version no longer supported
  
  // Misc
  permissionDenied,     // User lacks required permissions
  conflictingAccounts,  // Multiple accounts with same info
  passwordExpired,      // Password needs to be updated
  deviceNotTrusted,     // Device not in trusted devices list
  
  unknown               // Unspecified error
}
