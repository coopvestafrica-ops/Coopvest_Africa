import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:shared_preferences/shared_preferences.dart';

/// A service that handles biometric authentication across different platforms
/// with enhanced security features including attempt tracking and lockout management.
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  static BiometricService get instance => _instance;

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastAuthKey = 'biometric_last_auth';
  static const String _failedAttemptsKey = 'biometric_failed_attempts';
  static const String _lastFailedAttemptKey = 'biometric_last_failed';
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 30);
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  SharedPreferences? _prefs;
  
  bool? _isAvailable;
  List<BiometricType>? _availableBiometrics;
  String? _error;
  Timer? _lockoutTimer;

  BiometricService._internal();

  /// Initialize the biometric service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await checkBiometricAvailability();
      await _checkLockoutStatus();
    } catch (e) {
      _error = 'Failed to initialize biometric service: $e';
      debugPrint(_error);
    }
  }

  /// Check if device is currently locked out from biometric auth
  Future<bool> _checkLockoutStatus() async {
    if (_prefs == null) return false;

    final failedAttempts = _prefs!.getInt(_failedAttemptsKey) ?? 0;
    final lastFailedAttempt = _prefs!.getInt(_lastFailedAttemptKey);

    if (failedAttempts >= _maxFailedAttempts && lastFailedAttempt != null) {
      final lastFailed = DateTime.fromMillisecondsSinceEpoch(lastFailedAttempt);
      final lockoutEnds = lastFailed.add(_lockoutDuration);
      
      if (DateTime.now().isBefore(lockoutEnds)) {
        // Still in lockout period
        final remainingLockout = lockoutEnds.difference(DateTime.now());
        _startLockoutTimer(remainingLockout);
        return true;
      } else {
        // Lockout period has expired
        await _resetFailedAttempts();
        return false;
      }
    }
    return false;
  }

  /// Reset failed attempts counter
  Future<void> _resetFailedAttempts() async {
    await _prefs?.setInt(_failedAttemptsKey, 0);
    await _prefs?.remove(_lastFailedAttemptKey);
    _lockoutTimer?.cancel();
    _lockoutTimer = null;
  }

  /// Record a failed authentication attempt
  Future<void> _recordFailedAttempt() async {
    if (_prefs == null) return;

    final failedAttempts = (_prefs!.getInt(_failedAttemptsKey) ?? 0) + 1;
    await _prefs!.setInt(_failedAttemptsKey, failedAttempts);
    await _prefs!.setInt(_lastFailedAttemptKey, DateTime.now().millisecondsSinceEpoch);

    if (failedAttempts >= _maxFailedAttempts) {
      _startLockoutTimer(_lockoutDuration);
    }
  }

  /// Start lockout timer
  void _startLockoutTimer(Duration duration) {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer(duration, () {
      _resetFailedAttempts();
    });
  }

  /// Record a successful authentication
  Future<void> _recordSuccessfulAuth() async {
    await _resetFailedAttempts();
    await _prefs?.setInt(_lastAuthKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get the time of last successful authentication
  DateTime? getLastAuthTime() {
    final timestamp = _prefs?.getInt(_lastAuthKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Check if biometric authentication is available on the device
  Future<bool> checkBiometricAvailability() async {
    if (_isAvailable != null) return _isAvailable!;

    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      _isAvailable = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      
      if (_isAvailable!) {
        _availableBiometrics = await _localAuth.getAvailableBiometrics();
      }

      return _isAvailable!;
    } on PlatformException catch (e) {
      _error = 'Failed to check biometric availability: ${e.message}';
      debugPrint(_error);
      return false;
    }
  }

  /// Get the list of available biometric types
  List<BiometricType>? getAvailableBiometrics() => _availableBiometrics;

  /// Check if specific biometric type is available
  bool hasBiometricType(BiometricType type) {
    return _availableBiometrics?.contains(type) ?? false;
  }

  /// Get any error that occurred during biometric operations
  String? getError() => _error;

  /// Check if biometric authentication is enabled by the user
  bool isBiometricEnabled() {
    return _prefs?.getBool(_biometricEnabledKey) ?? false;
  }

  /// Enable or disable biometric authentication
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      if (enabled && !await checkBiometricAvailability()) {
        _error = 'Biometric authentication is not available on this device';
        return false;
      }

      await _prefs?.setBool(_biometricEnabledKey, enabled);
      return true;
    } catch (e) {
      _error = 'Failed to set biometric preference: $e';
      return false;
    }
  }

  /// Authenticate the user using available biometrics
  Future<BiometricResult> authenticate({
    String localizedReason = 'Please authenticate to continue',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
    bool sensitiveTransaction = true,
    Duration? authValidityDuration,
  }) async {
    // Check biometric availability
    if (!await checkBiometricAvailability()) {
      return const BiometricResult(
        success: false,
        error: 'Biometric authentication is not available',
        errorCode: BiometricErrorCode.notAvailable,
      );
    }

    // Check if biometrics is enabled
    if (!isBiometricEnabled()) {
      return const BiometricResult(
        success: false,
        error: 'Biometric authentication is not enabled',
        errorCode: BiometricErrorCode.notEnabled,
      );
    }

    // Check if device is in lockout
    if (await _checkLockoutStatus()) {
      return const BiometricResult(
        success: false,
        error: 'Device is temporarily locked due to too many failed attempts',
        errorCode: BiometricErrorCode.lockedOut,
      );
    }

    // Check if we have a recent successful auth
    if (authValidityDuration != null) {
      final lastAuth = getLastAuthTime();
      if (lastAuth != null) {
        final timeSinceLastAuth = DateTime.now().difference(lastAuth);
        if (timeSinceLastAuth < authValidityDuration) {
          return const BiometricResult(success: true);
        }
      }
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          sensitiveTransaction: sensitiveTransaction,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        await _recordSuccessfulAuth();
        return const BiometricResult(success: true);
      } else {
        await _recordFailedAttempt();
        return const BiometricResult(
          success: false,
          error: 'Authentication failed',
          errorCode: BiometricErrorCode.failed,
        );
      }
    } on PlatformException catch (e) {
      if (e.code == auth_error.lockedOut || e.code == auth_error.permanentlyLockedOut) {
        await _recordFailedAttempt();
      }
      return _handlePlatformException(e);
    } catch (e) {
      await _recordFailedAttempt();
      return BiometricResult(
        success: false,
        error: 'Authentication error: $e',
        errorCode: BiometricErrorCode.unknown,
      );
    }
  }

  /// Handle platform-specific biometric errors
  BiometricResult _handlePlatformException(PlatformException exception) {
    String error;
    BiometricErrorCode errorCode;

    switch (exception.code) {
      case auth_error.notAvailable:
        error = 'Biometric authentication is not available';
        errorCode = BiometricErrorCode.notAvailable;
        break;
      case auth_error.notEnrolled:
        error = 'No biometric credentials are enrolled on this device';
        errorCode = BiometricErrorCode.notEnrolled;
        break;
      case auth_error.lockedOut:
        error = 'Biometric authentication is temporarily locked (too many attempts)';
        errorCode = BiometricErrorCode.lockedOut;
        break;
      case auth_error.permanentlyLockedOut:
        error = 'Biometric authentication is permanently locked';
        errorCode = BiometricErrorCode.permanentlyLockedOut;
        break;
      case auth_error.passcodeNotSet:
        error = 'Device security is not enabled';
        errorCode = BiometricErrorCode.passcodeNotSet;
        break;
      default:
        error = exception.message ?? 'Unknown biometric error';
        errorCode = BiometricErrorCode.unknown;
    }

    _error = error;
    return BiometricResult(
      success: false,
      error: error,
      errorCode: errorCode,
    );
  }

  /// Get a description of the available biometric types with platform-specific details
  String getBiometricDescription() {
    if (_availableBiometrics == null || _availableBiometrics!.isEmpty) {
      return 'No biometric authentication available';
    }

    final List<String> descriptions = [];
    final platformDescriptions = <BiometricType, String>{
      BiometricType.face: defaultTargetPlatform == TargetPlatform.iOS ? 'Face ID' : 'Face Recognition',
      BiometricType.fingerprint: defaultTargetPlatform == TargetPlatform.iOS ? 'Touch ID' : 'Fingerprint',
      BiometricType.iris: 'Iris Scanner',
      BiometricType.strong: 'Strong Biometric Authentication',
      BiometricType.weak: 'Basic Biometric Authentication',
    };

    for (var type in _availableBiometrics!) {
      final description = platformDescriptions[type] ?? 'Unknown Biometric Type';
      descriptions.add(description);
    }

    return 'Available biometrics: ${descriptions.join(', ')}';
  }

  /// Check if the device supports secure biometrics (Class 3 or higher)
  Future<bool> hasSecureBiometrics() async {
    if (!await checkBiometricAvailability()) return false;
    
    return _availableBiometrics?.any((type) => 
      type == BiometricType.strong || 
      type == BiometricType.face || 
      type == BiometricType.iris
    ) ?? false;
  }

  /// Check if this is an Apple device with Face ID
  bool get hasFaceId {
    return defaultTargetPlatform == TargetPlatform.iOS && 
           hasBiometricType(BiometricType.face);
  }

  /// Check if this is an Apple device with Touch ID
  bool get hasTouchId {
    return defaultTargetPlatform == TargetPlatform.iOS && 
           hasBiometricType(BiometricType.fingerprint);
  }

  /// Get security level of available biometrics
  BiometricSecurityLevel getBiometricSecurityLevel() {
    if (_isAvailable != true) return BiometricSecurityLevel.none;
    
    if (_availableBiometrics?.contains(BiometricType.strong) ?? false) {
      return BiometricSecurityLevel.strong;
    }
    
    if (_availableBiometrics?.any((type) => 
      type == BiometricType.face || 
      type == BiometricType.iris ||
      type == BiometricType.fingerprint
    ) ?? false) {
      return BiometricSecurityLevel.standard;
    }
    
    if (_availableBiometrics?.contains(BiometricType.weak) ?? false) {
      return BiometricSecurityLevel.weak;
    }
    
    return BiometricSecurityLevel.none;
  }

  /// Clear any stored biometric preferences and security state
  Future<void> clear() async {
    await _prefs?.remove(_biometricEnabledKey);
    await _prefs?.remove(_lastAuthKey);
    await _prefs?.remove(_failedAttemptsKey);
    await _prefs?.remove(_lastFailedAttemptKey);
    _lockoutTimer?.cancel();
    _lockoutTimer = null;
    _isAvailable = null;
    _availableBiometrics = null;
    _error = null;
  }

  /// Get the remaining lockout duration, if any
  Duration? getRemainingLockoutDuration() {
    if (_prefs == null) return null;

    final lastFailedAttempt = _prefs!.getInt(_lastFailedAttemptKey);
    final failedAttempts = _prefs!.getInt(_failedAttemptsKey) ?? 0;

    if (failedAttempts >= _maxFailedAttempts && lastFailedAttempt != null) {
      final lastFailed = DateTime.fromMillisecondsSinceEpoch(lastFailedAttempt);
      final lockoutEnds = lastFailed.add(_lockoutDuration);
      
      if (DateTime.now().isBefore(lockoutEnds)) {
        return lockoutEnds.difference(DateTime.now());
      }
    }
    return null;
  }

  /// Get current number of failed attempts
  int getFailedAttempts() {
    return _prefs?.getInt(_failedAttemptsKey) ?? 0;
  }

  /// Get remaining attempts before lockout
  int getRemainingAttempts() {
    final failedAttempts = getFailedAttempts();
    return _maxFailedAttempts - failedAttempts;
  }

  /// Clean up any resources
  void dispose() {
    _lockoutTimer?.cancel();
  }
}

/// Represents the result of a biometric authentication attempt
class BiometricResult {
  final bool success;
  final String? error;
  final BiometricErrorCode? errorCode;

  const BiometricResult({
    required this.success,
    this.error,
    this.errorCode,
  });

  @override
  String toString() => 'BiometricResult(success: $success, error: $error, errorCode: $errorCode)';
}

/// Enum representing different biometric error codes
enum BiometricErrorCode {
  notAvailable,
  notEnabled,
  notEnrolled,
  failed,
  lockedOut,
  permanentlyLockedOut,
  passcodeNotSet,
  unknown,
}

/// Enum representing the security level of available biometric authentication
enum BiometricSecurityLevel {
  /// No biometric authentication available
  none,
  
  /// Basic biometric authentication (Class 1)
  weak,
  
  /// Standard biometric authentication (Class 2)
  standard,
  
  /// Strong biometric authentication (Class 3)
  strong
}
