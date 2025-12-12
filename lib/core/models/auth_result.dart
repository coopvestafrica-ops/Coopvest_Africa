import 'package:equatable/equatable.dart';

/// Represents the result of an authentication attempt
class AuthResult extends Equatable {
  /// Whether the authentication was successful
  final bool isSuccess;

  /// The authentication token (JWT) if successful
  final String? token;

  /// The refresh token if provided
  final String? refreshToken;

  /// Any error message if authentication failed
  final String? error;

  /// The type of error that occurred
  final AuthErrorType? errorType;

  /// Additional data returned with the authentication result
  final Map<String, dynamic>? data;

  /// The timestamp when this result was created
  final DateTime timestamp;
  
  /// The date when the user became a member
  final DateTime? memberSince;

  /// Whether the user is eligible for loans based on membership duration
  bool get isEligibleForLoans {
    if (memberSince == null) return false;
    final membershipDuration = DateTime.now().difference(memberSince!);
    return membershipDuration.inDays >= 180; // 6 months = approximately 180 days
  }

  /// The remaining days until loan eligibility
  int get daysUntilLoanEligible {
    if (memberSince == null) return 180;
    final membershipDuration = DateTime.now().difference(memberSince!);
    final remainingDays = 180 - membershipDuration.inDays;
    return remainingDays > 0 ? remainingDays : 0;
  }

  /// Creates an authentication result
  AuthResult({
    required this.isSuccess,
    this.token,
    this.refreshToken,
    this.error,
    this.errorType,
    this.data,
    DateTime? timestamp,
    this.memberSince,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a successful authentication result
  factory AuthResult.success({
    required String token,
    String? refreshToken,
    Map<String, dynamic>? data,
    DateTime? memberSince,
  }) {
    return AuthResult(
      isSuccess: true,
      token: token,
      refreshToken: refreshToken,
      data: data,
      memberSince: memberSince,
    );
  }

  /// Creates a failed authentication result
  factory AuthResult.failure({
    required String error,
    AuthErrorType errorType = AuthErrorType.unknown,
    Map<String, dynamic>? data,
  }) {
    return AuthResult(
      isSuccess: false,
      error: error,
      errorType: errorType,
      data: data,
    );
  }

  /// Creates an authentication result for invalid credentials
  factory AuthResult.invalidCredentials([String? message]) {
    return AuthResult(
      isSuccess: false,
      error: message ?? 'Invalid username or password',
      errorType: AuthErrorType.invalidCredentials,
    );
  }

  /// Creates an authentication result for network errors
  factory AuthResult.networkError([String? message]) {
    return AuthResult(
      isSuccess: false,
      error: message ?? 'Network error occurred',
      errorType: AuthErrorType.network,
    );
  }

  /// Creates an authentication result for server errors
  factory AuthResult.serverError([String? message]) {
    return AuthResult(
      isSuccess: false,
      error: message ?? 'Server error occurred',
      errorType: AuthErrorType.server,
    );
  }

  /// Creates an authentication result for expired tokens
  factory AuthResult.tokenExpired([String? message]) {
    return AuthResult(
      isSuccess: false,
      error: message ?? 'Authentication token has expired',
      errorType: AuthErrorType.tokenExpired,
    );
  }

  /// Creates an authentication result for account lockouts
  factory AuthResult.accountLocked({
    String? message,
    DateTime? unlockTime,
  }) {
    return AuthResult(
      isSuccess: false,
      error: message ?? 'Account is locked',
      errorType: AuthErrorType.accountLocked,
      data: unlockTime != null ? {'unlockTime': unlockTime.toIso8601String()} : null,
    );
  }

  /// Creates an authentication result for required MFA
  factory AuthResult.mfaRequired({
    required String mfaToken,
    List<String>? availableMethods,
  }) {
    return AuthResult(
      isSuccess: false,
      error: 'Multi-factor authentication required',
      errorType: AuthErrorType.mfaRequired,
      data: {
        'mfaToken': mfaToken,
        if (availableMethods != null) 'availableMethods': availableMethods,
      },
    );
  }

  /// Creates an authentication result for biometric authentication requirement
  factory AuthResult.biometricRequired([String? message]) {
    return AuthResult(
      isSuccess: false,
      error: message ?? 'Biometric authentication required',
      errorType: AuthErrorType.biometricRequired,
    );
  }

  /// Whether this result indicates a recoverable error
  bool get isRecoverable => errorType?.isRecoverable ?? false;

  /// Whether this result requires additional authentication steps
  bool get requiresAdditionalSteps => 
    errorType == AuthErrorType.mfaRequired ||
    errorType == AuthErrorType.biometricRequired;

  /// The unlock time for locked accounts
  DateTime? get unlockTime {
    if (errorType != AuthErrorType.accountLocked || data == null) {
      return null;
    }
    final unlockTimeStr = data!['unlockTime'] as String?;
    if (unlockTimeStr == null) return null;
    return DateTime.tryParse(unlockTimeStr);
  }

  /// The MFA token if MFA is required
  String? get mfaToken => data?['mfaToken'] as String?;

  /// Available MFA methods if MFA is required
  List<String>? get mfaMethods => 
    (data?['availableMethods'] as List<dynamic>?)?.cast<String>();

  /// Creates a copy of this result with some fields replaced
  AuthResult copyWith({
    bool? isSuccess,
    String? token,
    String? refreshToken,
    String? error,
    AuthErrorType? errorType,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    DateTime? memberSince,
  }) {
    return AuthResult(
      isSuccess: isSuccess ?? this.isSuccess,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      error: error ?? this.error,
      errorType: errorType ?? this.errorType,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      memberSince: memberSince ?? this.memberSince,
    );
  }

  @override
  List<Object?> get props => [
    isSuccess,
    token,
    refreshToken,
    error,
    errorType,
    data,
    timestamp,
    memberSince,
  ];

  @override
  String toString() {
    if (isSuccess) {
      return 'AuthResult.success(token: ${_maskToken(token)}, '
          'refreshToken: ${_maskToken(refreshToken)})';
    } else {
      return 'AuthResult.failure(error: $error, type: $errorType)';
    }
  }

  /// Masks a token for secure logging
  String? _maskToken(String? token) {
    if (token == null) return null;
    if (token.length <= 8) return '***';
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }
}

/// Types of authentication errors that can occur
enum AuthErrorType {
  /// Invalid username or password
  invalidCredentials(true),

  /// Network connectivity issues
  network(true),

  /// Server-side errors
  server(true),

  /// Authentication token has expired
  tokenExpired(true),

  /// Account is temporarily locked
  accountLocked(true),

  /// Multi-factor authentication required
  mfaRequired(true),

  /// Biometric authentication required
  biometricRequired(true),

  /// Account is disabled or deleted
  accountDisabled(false),

  /// User is not authorized for this operation
  unauthorized(false),

  /// Session has been invalidated
  sessionInvalidated(false),

  /// Unknown or unexpected error
  unknown(true);

  /// Whether this error type can be recovered from
  final bool isRecoverable;

  const AuthErrorType(this.isRecoverable);

  /// Get a user-friendly message for this error type
  String get message {
    switch (this) {
      case AuthErrorType.invalidCredentials:
        return 'Invalid username or password';
      case AuthErrorType.network:
        return 'Network error occurred';
      case AuthErrorType.server:
        return 'Server error occurred';
      case AuthErrorType.tokenExpired:
        return 'Your session has expired';
      case AuthErrorType.accountLocked:
        return 'Account is temporarily locked';
      case AuthErrorType.mfaRequired:
        return 'Additional authentication required';
      case AuthErrorType.biometricRequired:
        return 'Biometric authentication required';
      case AuthErrorType.accountDisabled:
        return 'Account is disabled';
      case AuthErrorType.unauthorized:
        return 'You are not authorized for this action';
      case AuthErrorType.sessionInvalidated:
        return 'Your session has been invalidated';
      case AuthErrorType.unknown:
        return 'An unknown error occurred';
    }
  }
}
