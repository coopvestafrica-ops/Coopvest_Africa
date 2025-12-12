import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../models/login_response.dart';
import '../models/session_info.dart';
import '../exceptions/auth_exception.dart';
import '../utils/api_utils.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  mfaRequired,
  error,
  securityLocked
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  static const _securityLockTimeout = Duration(minutes: 15);
  static const _sessionTimeout = Duration(minutes: 30);
  static const _tokenRefreshInterval = Duration(minutes: 4);
  static const _maxFailedAttempts = 5;

  AuthStatus _status = AuthStatus.initial;
  User? _currentUser;
  String? _token;
  SessionInfo? _sessionInfo;
  String? _errorMessage;
  AuthErrorType? _errorType;
  DateTime? _lastAuthenticated;
  DateTime? _lastActivity;
  Timer? _sessionTimer;
  Timer? _tokenRefreshTimer;
  Timer? _securityLockTimer;
  Timer? _inactivityTimer;
  StreamSubscription? _sessionSubscription;
  int _failedAttempts = 0;
  String? _mfaPendingId;
  bool _biometricsEnabled = false;
  bool _rememberMe = false;

  AuthProvider(this._authService) {
    _initialize();
  }

  // Getters
  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get token => _token;
  SessionInfo? get sessionInfo => _sessionInfo;
  String? get errorMessage => _errorMessage;
  AuthErrorType? get errorType => _errorType;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAuthenticating => _status == AuthStatus.authenticating;
  bool get isMfaRequired => _status == AuthStatus.mfaRequired;
  bool get isSecurityLocked => _status == AuthStatus.securityLocked;
  bool get hasError => _status == AuthStatus.error;
  bool get isBiometricsEnabled => _biometricsEnabled;
  Duration? get sessionAge => _lastAuthenticated != null 
    ? DateTime.now().difference(_lastAuthenticated!) 
    : null;

  Future<void> _initialize() async {
    try {
      _status = AuthStatus.authenticating;
      notifyListeners();

      // Restore previous session if remember me was enabled
      _rememberMe = await _authService.getRememberMe();
      
      _sessionSubscription = _authService.onSessionChanged.listen(_handleSessionChange);
      _biometricsEnabled = await _authService.canUseBiometrics();
      
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null && _rememberMe) {
        await _updateAuthState(currentUser);
      } else {
        _clearAuthState();
      }
    } catch (e) {
      _handleError(e);
    } finally {
      notifyListeners();
    }
  }

  void _updateLastActivity() {
    _lastActivity = DateTime.now();
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_sessionTimeout, () {
      if (_status == AuthStatus.authenticated) {
        final inactivityDuration = DateTime.now().difference(_lastActivity!);
        if (inactivityDuration >= _sessionTimeout) {
          _handleSessionTimeout();
        }
      }
    });
  }

  void _handleSessionTimeout() {
    logout(reason: 'Session timed out due to inactivity');
  }

  Future<ApiResponse<LoginResponse>> login(String email, String password, {
    bool isStaff = false,
    bool useBiometrics = false,
    bool rememberMe = false
  }) async {
    if (isSecurityLocked) {
      return ApiResponse.error(
        error: 'Account is temporarily locked. Try again later.',
        errorCode: AuthErrorType.accountLocked.toString(),
      );
    }

    try {
      _status = AuthStatus.authenticating;
      _clearError();
      notifyListeners();

      final response = useBiometrics 
        ? await _authService.loginWithBiometrics()
        : await _authService.login(email, password, isStaff: isStaff);
      
      if (response.requiresMfa) {
        _status = AuthStatus.mfaRequired;
        _mfaPendingId = response.mfaPendingId;
        notifyListeners();
        return ApiResponse.error(
          error: 'Multi-factor authentication required',
          errorCode: AuthErrorType.mfaRequired.toString(),
          errorData: {'mfaPendingId': _mfaPendingId},
        );
      }

      _rememberMe = rememberMe;
      await _authService.setRememberMe(rememberMe);
      await _updateAuthState(response);
      _failedAttempts = 0;
      return ApiResponse.success(response);
    } catch (e) {
      final error = _handleError(e);
      
      // Handle security-related errors
      if (error.isSecurityError || error.type == AuthErrorType.invalidCredentials) {
        _failedAttempts++;
        if (_failedAttempts >= _maxFailedAttempts) {
          _enableSecurityLock();
        }
      }

      return ApiResponse.error(
        error: _errorMessage ?? 'Login failed',
        errorCode: error.type.toString(),
        errorData: error.errorData,
        retryAfter: error.retryAfter,
      );
    }
  }

  Future<ApiResponse<LoginResponse>> verifyMfa(String code) async {
    if (_mfaPendingId == null || !isMfaRequired) {
      return ApiResponse.error(
        error: 'Invalid MFA state',
        errorCode: 'MFA_INVALID_STATE',
      );
    }

    try {
      final response = await _authService.verifyMfa(_mfaPendingId!, code);
      await _updateAuthState(response);
      _mfaPendingId = null;
      return ApiResponse.success(response);
    } catch (e) {
      final error = _handleError(e);
      return ApiResponse.error(
        error: _errorMessage ?? 'MFA verification failed',
        errorCode: error.type.toString(),
        errorData: error.errorData,
      );
    }
  }

  Future<ApiResponse<void>> enableBiometrics() async {
    try {
      await _authService.enableBiometrics();
      _biometricsEnabled = true;
      notifyListeners();
      return ApiResponse.success(null);
    } catch (e) {
      final error = _handleError(e);
      return ApiResponse.error(
        error: _errorMessage ?? 'Failed to enable biometrics',
        errorCode: error.type.toString(),
      );
    }
  }

  Future<ApiResponse<void>> disableBiometrics() async {
    try {
      await _authService.disableBiometrics();
      _biometricsEnabled = false;
      notifyListeners();
      return ApiResponse.success(null);
    } catch (e) {
      final error = _handleError(e);
      return ApiResponse.error(
        error: _errorMessage ?? 'Failed to disable biometrics',
        errorCode: error.type.toString(),
      );
    }
  }

  Future<ApiResponse<void>> logout({
    bool fromAllDevices = false,
    String? reason
  }) async {
    try {
      await _authService.logout();
      
      // Clear saved login state if it was a manual logout
      if (reason == null) {
        await _authService.setRememberMe(false);
      }
      
      _clearAuthState();
      if (reason != null) {
        _errorMessage = reason;
        _errorType = AuthErrorType.sessionExpired;
      }
      
      return ApiResponse.success(null);
    } catch (e) {
      final error = _handleError(e);
      return ApiResponse.error(
        error: _errorMessage ?? 'Logout failed',
        errorCode: error.type.toString(),
      );
    }
  }

  Future<ApiResponse<User>> updateProfile(User user) async {
    try {
      await _authService.updateProfile(user);
      _currentUser = user;
      notifyListeners();
      return ApiResponse.success(user);
    } catch (e) {
      final error = _handleError(e);
      return ApiResponse.error(
        error: _errorMessage ?? 'Profile update failed',
        errorCode: error.type.toString(),
        errorData: error.errorData,
      );
    }
  }

  Future<void> refreshToken() async {
    try {
      final newToken = await _authService.getToken();
      if (newToken != _token) {
        _token = newToken;
        _lastAuthenticated = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      final error = _handleError(e);
      if (error.requiresReauth) {
        await logout();
      }
    }
  }

  Future<void> _updateAuthState(dynamic userOrResponse) async {
    if (userOrResponse is LoginResponse) {
      _token = userOrResponse.token;
      final user = await _authService.getCurrentUser();
      if (user == null) {
        throw AuthException(
          'Failed to get user details',
          type: AuthErrorType.invalidSession,
        );
      }
      _currentUser = user;
    } else if (userOrResponse is User) {
      _currentUser = userOrResponse;
      _token = await _authService.getToken();
    } else {
      throw ArgumentError('Invalid argument type for _updateAuthState');
    }
    
    _status = AuthStatus.authenticated;
    _lastAuthenticated = DateTime.now();
    _clearError();
    _startTokenRefreshTimer();
    notifyListeners();
  }

  void _clearAuthState() {
    _status = AuthStatus.unauthenticated;
    _currentUser = null;
    _token = null;
    _sessionInfo = null;
    _lastAuthenticated = null;
    _mfaPendingId = null;
    _clearError();
    _stopTimers();
    notifyListeners();
  }

  AuthException _handleError(dynamic error) {
    // Convert non-AuthException errors to AuthException
    final authError = error is AuthException ? error : AuthException(
      error.toString(),
      type: AuthErrorType.unknown,
    );

    // Update error state
    _errorMessage = authError.message;
    _errorType = authError.type;

    // Handle different error scenarios
    if (authError.type == AuthErrorType.mfaRequired) {
      _status = AuthStatus.mfaRequired;
    } else if (authError.isSecurityError) {
      _enableSecurityLock();
      _status = AuthStatus.securityLocked;
    } else if (authError.requiresReauth || 
              authError.type == AuthErrorType.sessionExpired ||
              authError.type == AuthErrorType.tokenRevoked) {
      _clearAuthState();
      _status = AuthStatus.unauthenticated;
    } else {
      _status = AuthStatus.error;
      if (authError.isRetryable) {
        // Schedule auto-retry for retryable errors
        Future.delayed(authError.retryAfter ?? const Duration(seconds: 30), () {
          if (_status == AuthStatus.error) {
            refreshToken();
          }
        });
      }
    }

    notifyListeners();
    return authError;
  }

  void _handleSessionChange(SessionInfo? session) {
    _sessionInfo = session;

    if (session == null) {
      _clearAuthState();
      _handleError(AuthException(
        'Session ended',
        type: AuthErrorType.sessionExpired
      ));
    } else if (_status == AuthStatus.authenticated) {
      if (DateTime.now().difference(_lastActivity ?? DateTime.now()) >= _sessionTimeout) {
        _clearAuthState();
        _handleError(AuthException(
          'Session timed out due to inactivity',
          type: AuthErrorType.sessionExpired
        ));
      } else {
        _updateLastActivity();
      }
    }
    notifyListeners();
  }

  void _enableSecurityLock() {
    _status = AuthStatus.securityLocked;
    _securityLockTimer?.cancel();
    _securityLockTimer = Timer(_securityLockTimeout, () {
      if (isSecurityLocked) {
        _status = AuthStatus.unauthenticated;
        _failedAttempts = 0;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    _errorType = null;
  }

  void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(
      _tokenRefreshInterval,
      (_) async {
        if (_authService.needsTokenRefresh) {
          try {
            await refreshToken();
            _updateLastActivity();
          } catch (e) {
            // If token refresh fails, try one more time after a short delay
            await Future.delayed(const Duration(seconds: 5));
            try {
              await refreshToken();
              _updateLastActivity();
            } catch (e) {
              // If second attempt fails, handle as authentication error
              _handleError(e);
            }
          }
        }
      },
    );
  }

  void _stopTimers() {
    _sessionTimer?.cancel();
    _tokenRefreshTimer?.cancel();
    _securityLockTimer?.cancel();
  }

  @override
  void dispose() {
    _stopTimers();
    _sessionSubscription?.cancel();
    super.dispose();
  }
}
