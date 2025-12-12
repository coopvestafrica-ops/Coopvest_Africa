import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:synchronized/synchronized.dart';

import '../config/api_config.dart';
import '../exceptions/api_exception.dart';
import '../exceptions/auth_exception.dart';
import '../models/auth_state.dart';
import '../models/login_response.dart';
import '../models/session_info.dart';
import '../models/user.dart';
import '../models/user_role.dart';

import 'base_service.dart';

/// Tracks error occurrences within a time window
class ErrorTracker {
  final Duration windowDuration;
  final int maxErrors;
  final Queue<DateTime> _errorTimes = Queue<DateTime>();
  DateTime? _blockUntil;

  ErrorTracker({
    required this.maxErrors,
    required this.windowDuration,
  });

  void recordError() {
    final now = DateTime.now();
    _errorTimes.addLast(now);

    // Remove errors outside the window
    while (_errorTimes.isNotEmpty &&
           now.difference(_errorTimes.first) > windowDuration) {
      _errorTimes.removeFirst();
    }

    // If we exceed max errors, set block time
    if (_errorTimes.length >= maxErrors) {
      _blockUntil = now.add(AuthService._blockDuration);
      _errorTimes.clear();
    }
  }

  Duration? getBlockDuration() {
    if (_blockUntil == null) return null;
    
    final remaining = _blockUntil!.difference(DateTime.now());
    if (remaining.isNegative) {
      _blockUntil = null;
      return null;
    }
    
    return remaining;
  }

  void clear() {
    _errorTimes.clear();
    _blockUntil = null;
  }
}


class AuthService extends BaseService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _roleKey = 'user_role';
  static const String _permissionsKey = 'user_permissions';
  static const String _sessionKey = 'session_info';
  static const Duration _tokenRefreshThreshold = Duration(minutes: 5);
  static const Duration _sessionTimeout = Duration(hours: 24);
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 30);
  static const Duration _errorWindowDuration = Duration(minutes: 5);
  static const int _maxErrorsBeforeBlock = 5;
  static const Duration _blockDuration = Duration(minutes: 15);

  static AuthService? _instance;
  static final _setupLock = Lock();

  static ApiException _createAuthError(
    String message, {
    AuthErrorType type = AuthErrorType.unknown,
    Map<String, dynamic>? data,
    Duration? retryAfter,
  }) {
    return ApiException(
      message,
      errorData: {
        'type': type.toString().split('.').last,
        'statusCode': _getStatusCodeForAuthError(type),
        if (data != null) ...data,
        if (retryAfter != null) 'retryAfter': retryAfter.inSeconds,
      },
    );
  }

  static int _getStatusCodeForAuthError(AuthErrorType type) {
    switch (type) {
      case AuthErrorType.invalidCredentials:
        return 401;
      case AuthErrorType.invalidToken:
        return 401;
      case AuthErrorType.sessionExpired:
        return 401;
      case AuthErrorType.invalidSession:
        return 403;
      case AuthErrorType.accountDisabled:
        return 403;
      case AuthErrorType.accountLocked:
        return 423;
      case AuthErrorType.tooManyAttempts:
        return 429;
      case AuthErrorType.serverError:
        return 500;
      case AuthErrorType.networkError:
        return 0;
      default:
        return 400;
    }
  }



  static Future<void> initialize() async {
    await _setupLock.synchronized(() async {
      if (_instance != null) return; // Already initialized

      final prefs = await SharedPreferences.getInstance();
      final secureStorage = FlutterSecureStorage(
        aOptions: const AndroidOptions(
          encryptedSharedPreferences: true,
          keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
          storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
        ),
        iOptions: const IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
          synchronizable: true,
        ),
      );

      // Create the instance first
      final instance = AuthService._internal(prefs, secureStorage);

      // Perform all async initialization here to prevent race conditions
      await instance._initializeTokenExpiry();
      await instance._initializeSession();
      instance._startSessionTimer();
      instance._startTokenRefreshTimer();

      // Only assign the fully initialized instance
      _instance = instance;
    });
  }
  
  static AuthService get instance {
    if (_instance == null) {
      throw StateError('AuthService must be initialized before use. Call AuthService.initialize() first.');
    }
    return _instance!;
  }

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _lock = Lock(); // For synchronizing critical sections

  DateTime? _tokenExpiry;
  String? _cachedToken; // In-memory token cache
  Completer<void>? _tokenRefreshCompleter;
  bool _isRefreshing = false;
  
  int _loginAttempts = 0;
  DateTime? _lastLoginAttempt;
  SessionInfo? _currentSession;
  Timer? _sessionTimer;
  Timer? _tokenRefreshTimer;
  
  final _sessionController = StreamController<SessionInfo?>.broadcast();
  final _authStateController = StreamController<AuthState>.broadcast();
  
  // Enhanced error tracking
  late final ErrorTracker _errorTracker;

  bool _isLockedOut() {
    if (_lastLoginAttempt == null) return false;
    if (_loginAttempts < _maxLoginAttempts) return false;
    return DateTime.now().difference(_lastLoginAttempt!) < _lockoutDuration;
  }

  Duration _getRemainingLockoutTime() {
    if (_lastLoginAttempt == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_lastLoginAttempt!);
    return _lockoutDuration - elapsed;
  }

  void _recordLoginAttempt({required bool success}) {
    if (success) {
      _loginAttempts = 0;
      _lastLoginAttempt = null;
    } else {
      _loginAttempts++;
      _lastLoginAttempt = DateTime.now();
    }
  }

  AuthService._internal(this._prefs, FlutterSecureStorage? storage) : 
    _secureStorage = storage ?? const FlutterSecureStorage() {
    _errorTracker = ErrorTracker(
      maxErrors: _maxErrorsBeforeBlock,
      windowDuration: _errorWindowDuration,
    );
  }

  // For testing purposes
  @visibleForTesting
  factory AuthService.forTesting(SharedPreferences prefs) {
    return AuthService._internal(
      prefs,
      const FlutterSecureStorage(),
    );
  }

  Future<void> _initializeTokenExpiry() async {
    final initialToken = await _secureStorage.read(key: _tokenKey);
    if (initialToken != null) {
      _cachedToken = initialToken;
      try {
        final claims = JwtDecoder.decode(initialToken);
        _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(claims['exp'] * 1000);
      } catch (e) {
        // Invalid token, clear it
        await Future.wait([
          _secureStorage.delete(key: _tokenKey),
          _secureStorage.delete(key: _refreshTokenKey),
        ]);
        _cachedToken = null;
        _tokenExpiry = null;
        _endSession();
      }
    }
  }

  Future<void> _initializeSession() async {
    final sessionData = _prefs.getString(_sessionKey);
    if (sessionData != null) {
      try {
        _currentSession = SessionInfo.fromJson(jsonDecode(sessionData));
        if (!isSessionActive) {
          await _endSession();
        }
      } catch (e) {
        await _endSession();
      }
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    if (_currentSession != null && !isSessionActive) {
      await _endSession();
    }
  }

  Future<void> _updateSession() async {
    if (_currentSession != null) {
      final updatedSession = _currentSession!.copyWith(
        lastActivityTime: DateTime.now(),
      );
      _currentSession = updatedSession;
      await _prefs.setString(_sessionKey, jsonEncode(updatedSession.toJson()));
      _sessionController.add(updatedSession);
    }
  }



  Future<void> _endSession() async {
    await _lock.synchronized(() async {
      try {
        // Clear sensitive data
        await Future.wait([
          _secureStorage.delete(key: _tokenKey),
          _secureStorage.delete(key: _refreshTokenKey),
          _prefs.remove(_userKey),
          _prefs.remove(_sessionKey),
          _prefs.remove(_roleKey),
          _prefs.remove(_permissionsKey),
        ]);

        // Reset state
        _currentSession = null;
        _tokenExpiry = null;
        _cachedToken = null;
        _errorTracker.clear();

        // Cancel timers
        _sessionTimer?.cancel();
        _tokenRefreshTimer?.cancel();

        // Notify listeners
        _sessionController.add(null);
        _authStateController.add(AuthState.unauthenticated);

        developer.log(
          'Session ended',
          name: 'AuthService',
        );
      } catch (e) {
        developer.log(
          'Error ending session: $e',
          name: 'AuthService',
          error: e,
        );
        rethrow;
      }
    });
  }

  void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) async {
        if (needsTokenRefresh) {
          try {
            await _refreshToken();
          } catch (e) {
            developer.log(
              'Background token refresh failed: $e',
              name: 'AuthService',
              error: e,
            );
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _tokenRefreshTimer?.cancel();
    _sessionController.close();
    _authStateController.close();
    super.dispose();
  }

  Future<String?> get token async {
    if (_cachedToken != null) {
      return _cachedToken;
    }
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      developer.log(
        'Error reading token from secure storage: $e',
        name: 'AuthService',
        error: e,
      );
      // If secure storage fails, clear the session to prevent inconsistencies
      await _endSession();
      return null;
    }
  }
  
  Future<String?> get refreshToken async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      developer.log(
        'Error reading refresh token from secure storage: $e',
        name: 'AuthService',
        error: e,
      );
      // If secure storage fails, clear the session to prevent inconsistencies
      await _endSession();
      return null;
    }
  }
  
  bool get isAuthenticated => _currentSession != null;
  bool get isSessionActive => _currentSession?.lastActivityTime
    .add(_sessionTimeout).isAfter(DateTime.now()) ?? false;
    
  bool get needsTokenRefresh {
    if (_tokenExpiry == null) return false;
    final now = DateTime.now();
    return now.isAfter(_tokenExpiry!.subtract(_tokenRefreshThreshold));
  }

  Stream<SessionInfo?> get onSessionChanged => _sessionController.stream;

  Future<String> getToken() async {
    // Update session activity every time a token is requested for an API call
    await _updateSession();

    final currentToken = await token;
    if (currentToken == null) {
      throw AuthException(
        'No authentication token found. User must be logged in.',
        type: AuthErrorType.invalidSession
      );
    }
    if (needsTokenRefresh) {
      return _refreshToken();
    }
    return currentToken;
  }

  Future<LoginResponse> login(String email, String password, {bool isStaff = false}) async {
    _authStateController.add(AuthState.authenticating);

    // Check general error rate limiting
    final blockDuration = _errorTracker.getBlockDuration();
    if (blockDuration != null) {
      _authStateController.add(AuthState.accountLocked);
      throw _createAuthError(
        'Too many errors. Try again in ${blockDuration.inMinutes} minutes',
        type: AuthErrorType.tooManyAttempts,
        retryAfter: blockDuration,
      );
    }

    // Check specific login attempts
    if (_isLockedOut()) {
      final remainingTime = _getRemainingLockoutTime();
      _authStateController.add(AuthState.accountLocked);
      throw _createAuthError(
        'Too many login attempts. Try again in ${remainingTime.inMinutes} minutes',
        type: AuthErrorType.tooManyAttempts,
        retryAfter: remainingTime,
        data: {'attempts': _loginAttempts},
      );
    }

    try {
      final deviceInfo = await _getDeviceInfo();
      final endpoint = isStaff ? ApiConfig.staffLogin : ApiConfig.login;
      
      developer.log(
        'Login attempt: $email (staff: $isStaff)',
        name: 'AuthService',
      );
      
      final response = await super.post<Map<String, dynamic>>(
        path: endpoint,
        parser: (json) => json,
        body: {
          'email': email.trim().toLowerCase(),
          'password': password,
          'deviceInfo': deviceInfo,
        },
      );

      final token = response['accessToken'] as String?;
      final refreshToken = response['refreshToken'] as String?;
      final roleStr = response['role'] as String?;
      
      // Validate required fields
      if (token == null || refreshToken == null) {
        _recordLoginAttempt(success: false);
        throw _createAuthError(
          'Invalid response format: missing required fields',
          type: AuthErrorType.serverError,
          data: {
            'response': response,
            'missingFields': [
              if (token == null) 'token',
              if (refreshToken == null) 'refreshToken',
            ],
          },
        );
      }
      
      final userRole = isStaff && roleStr != null 
        ? _parseUserRole(roleStr) 
        : UserRole.member;
        
      // For admin roles, require MFA
      if (userRole == UserRole.admin) {
        final mfaVerified = await _verifyMFA();
        if (!mfaVerified) {
          throw _createAuthError(
            'MFA verification failed',
            type: AuthErrorType.mfaFailed,
            data: {'role': userRole.toString()},
          );
        }
      }

        // Validate and save tokens
        if (_isValidJwt(token) && _isValidJwt(refreshToken)) {
          _cachedToken = token;
          await Future.wait([
            _secureStorage.write(key: _tokenKey, value: token),
            _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
            _prefs.setString(_roleKey, response['role'] as String),
            if (response['permissions'] != null)
              _prefs.setString(_permissionsKey, jsonEncode(response['permissions'])),
          ]);
          
          // Update token expiry
          final claims = JwtDecoder.decode(token);
          _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(claims['exp'] * 1000);

          final user = await _getCurrentUser(token);
          await _saveUser(user);
          
          return LoginResponse(
            id: user.id,
            firstName: user.firstName,
            email: user.email,
            token: token,
            refreshToken: refreshToken,
            isEmailVerified: user.isEmailVerified,
            isPhoneVerified: user.isPhoneVerified,
            role: userRole,
          );
        } else {
          throw AuthException(
            'Invalid token format received',
            type: AuthErrorType.invalidToken,
          );
        }
    } on SocketException {
      _errorTracker.recordError();
      throw ApiException('No internet connection');
    } on FormatException {
      _errorTracker.recordError();
      throw ApiException('Invalid response format');
    } catch (e) {
      _errorTracker.recordError();
      if (e is ApiException || e is AuthException) rethrow;
      throw ApiException('An unexpected error occurred during login.');
    }
  }

  Future<bool> _verifyMFA() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      if (!canAuthenticate) {
        throw ApiException('Biometric authentication not available');
      }

      return await _localAuth.authenticate(
        localizedReason: 'Verify your identity to access admin features',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      throw ApiException('MFA verification failed: ${e.toString()}');
    }
  }

  UserRole _parseUserRole(String roleStr) {
    switch (roleStr.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'loan_staff':
        return UserRole.loanStaff;
      case 'finance_officer':
        return UserRole.financeOfficer;
      case 'compliance_officer':
        return UserRole.complianceOfficer;
      default:
        return UserRole.member;
    }
  }

  bool _isValidJwt(String token) {
    try {
      // Check if it's a valid JWT format
      if (!token.contains('.') || token.split('.').length != 3) return false;
      
      // Validate expiry
      final claims = JwtDecoder.decode(token);
      final expiry = DateTime.fromMillisecondsSinceEpoch(claims['exp'] * 1000);
      return expiry.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    
    final Map<String, dynamic> info = {
      'appName': packageInfo.appName,
      'packageName': packageInfo.packageName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
    };

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      info.addAll({
        'platform': 'android',
        'manufacturer': androidInfo.manufacturer,
        'model': androidInfo.model,
        'sdkInt': androidInfo.version.sdkInt,
        'deviceId': androidInfo.id,
      });
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      info.addAll({
        'platform': 'ios',
        'name': iosInfo.name,
        'model': iosInfo.model,
        'systemVersion': iosInfo.systemVersion,
        'deviceId': iosInfo.identifierForVendor,
      });
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      info.addAll({
        'platform': Platform.operatingSystem,
      });
    }

    return info;
  }

  Future<void> logout() async {
    try {
      final currentToken = await token;
      // Notify server for token revocation if we have a token
      if (currentToken != null) {
        // Use the base service's post method to be consistent
        await super.post(
          path: ApiConfig.logout,
          parser: (json) => json, // We don't care about the response
          token: currentToken,
        );
      }
    } catch (e) {
      developer.log(
        'Server-side logout failed, proceeding with client-side cleanup. Error: $e',
        name: 'AuthService',
      );
    } finally {
      // Ensure a full, clean session termination on the client
      await _endSession();
    }
  }

  Future<String> _refreshToken() async {
    // Prevent multiple simultaneous refresh attempts
    if (_isRefreshing && _tokenRefreshCompleter != null) {
      // The completer's future should hold the new token.
      return (await _tokenRefreshCompleter!.future) as String;
    }

    _isRefreshing = true;
    final completer = Completer<String>();
    _tokenRefreshCompleter = completer;

    try {
      final currentRefreshToken = await refreshToken;
      if (currentRefreshToken == null) {
        throw AuthException(
          'No refresh token found',
          type: AuthErrorType.sessionExpired,
        );
      }

      final response = await super.post<Map<String, dynamic>>(
        path: ApiConfig.refreshToken,
        parser: (json) => json,
        body: {'refreshToken': currentRefreshToken},
      );
      
      final newToken = response['accessToken'] as String?;
      if (newToken == null || !_isValidJwt(newToken)) {
        // This is a critical failure, likely means the refresh token is invalid/expired.
        throw _createAuthError(
          'Invalid token received during refresh',
          type: AuthErrorType.invalidToken,
        );
      }

      await _lock.synchronized(() async {
        await _secureStorage.write(key: _tokenKey, value: newToken);
        _cachedToken = newToken;
        final claims = JwtDecoder.decode(newToken);
        _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(claims['exp'] * 1000);
      });

      developer.log(
        'Token refreshed successfully',
        name: 'AuthService',
      );

      completer.complete(newToken);
      return newToken;
    } catch (e) {
      developer.log(
        'Token refresh failed: $e',
        name: 'AuthService',
        error: e,
      );

      try {
        if (e is AuthException) {
          if (e.type == AuthErrorType.sessionExpired ||
              e.type == AuthErrorType.invalidToken) {
            _authStateController.add(AuthState.sessionExpired);
            await _endSession();
          }
        }
        rethrow;
      } finally {
        // Ensure completer is always completed to prevent deadlocks.
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      }
    } finally {
      _isRefreshing = false;
      _tokenRefreshCompleter = null; // Clear the completer for the next refresh cycle
    }
  }

  Future<User> register({
    required String email,
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        path: ApiConfig.register,
        parser: (json) => json,
        body: {
          'email': email.trim().toLowerCase(),
          'username': username.trim(),
          'password': password,
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          if (phoneNumber != null) 'phone': phoneNumber.trim(),
        },
      );

      if (response['success'] == false) {
        _errorTracker.recordError();
        throw _createAuthError(
          response['message'] as String? ?? 'Registration failed',
          type: _mapRegistrationErrorType(response),
          data: response,
        );
      }

      if (response['user'] != null) {
        return User.fromJson(response['user'] as Map<String, dynamic>);
      }

      throw _createAuthError(
        'Invalid response format: missing user data',
        type: AuthErrorType.serverError,
        data: response,
      );
    } on SocketException {
      _errorTracker.recordError();
      throw AuthException(
        'No internet connection. Please check your network and try again.',
        type: AuthErrorType.networkError,
      );
    } on FormatException {
      _errorTracker.recordError();
      throw AuthException(
        'Invalid response format from server',
        type: AuthErrorType.serverError,
      );
    } catch (e) {
      _errorTracker.recordError();
      if (e is AuthException) rethrow;
      throw _createAuthError(
        e.toString(),
        type: AuthErrorType.unknown,
      );
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      // First try to get from local storage
      final userData = _prefs.getString(_userKey);
      if (userData != null) {
        return User.fromJson(jsonDecode(userData));
      }
      
      // If not in storage, try to fetch from server
      final currentToken = await token;
      if (currentToken != null) {
        return await _getCurrentUser(currentToken);
      }
      
      return null;
    } catch (e) {
      await logout();
      return null;
    }
  }

  Future<User> _getCurrentUser(String token) async {
    try {
      if (needsTokenRefresh) {
        token = await _refreshToken();
      }

      final response = await post<Map<String, dynamic>>(
        path: ApiConfig.currentUser,
        parser: (json) => json,
        token: token,
      );

      if (response['user'] != null) {
        final user = User.fromJson(response['user'] as Map<String, dynamic>);
        await _saveUser(user);
        return user;
      }

      throw AuthException(
        response['message'] as String? ?? 'Failed to get user data',
        type: AuthErrorType.invalidSession,
        errorData: response,
      );
    } on SocketException {
      _errorTracker.recordError();
      throw AuthException(
        'No internet connection',
        type: AuthErrorType.networkError,
      );
    } catch (e) {
      _errorTracker.recordError();
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to get user data: $e',
        type: AuthErrorType.unknown,
      );
    }
  }

  Future<void> _saveUser(User user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  Future<bool> getRememberMe() async {
    return _prefs.getBool('remember_me') ?? false;
  }

  Future<void> setRememberMe(bool value) async {
    await _prefs.setBool('remember_me', value);
  }

  Future<LoginResponse> loginWithBiometrics() async {
    try {
      final canAuthenticate = await canUseBiometrics();
      if (!canAuthenticate) {
        throw AuthException(
          'Biometric authentication not available',
          type: AuthErrorType.biometricsNotAvailable,
        );
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Log in with biometrics',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!authenticated) {
        throw AuthException(
          'Biometric verification failed',
          type: AuthErrorType.biometricsFailed,
        );
      }

      // Get stored credentials
      final email = await _secureStorage.read(key: 'biometric_email');
      final deviceId = await _secureStorage.read(key: 'biometric_device_id');

      if (email == null || deviceId == null) {
        throw AuthException(
          'No biometric login credentials found',
          type: AuthErrorType.biometricsNotAvailable,
        );
      }

      // Authenticate with server using biometric token
      final response = await post<Map<String, dynamic>>(
        path: ApiConfig.biometricLogin,
        parser: (json) => json,
        body: {
          'email': email,
          'deviceId': deviceId,
          'deviceInfo': await _getDeviceInfo(),
        },
      );

      return _handleLoginResponse(response);
    } catch (e) {
      _errorTracker.recordError();
      if (e is AuthException) rethrow;
      throw AuthException(
        'Biometric login failed: ${e.toString()}',
        type: AuthErrorType.biometricsFailed,
      );
    }
  }

  Future<LoginResponse> verifyMfa(String pendingId, String code) async {
    try {
      final response = await post<Map<String, dynamic>>(
        path: ApiConfig.verifyMfa,
        parser: (json) => json,
        body: {
          'pendingId': pendingId,
          'code': code,
          'deviceInfo': await _getDeviceInfo(),
        },
      );

      return _handleLoginResponse(response);
    } catch (e) {
      _errorTracker.recordError();
      if (e is AuthException) rethrow;
      throw AuthException(
        'MFA verification failed: ${e.toString()}',
        type: AuthErrorType.mfaFailed,
      );
    }
  }

  Future<void> enableBiometrics() async {
    try {
      final canAuthenticate = await canUseBiometrics();
      if (!canAuthenticate) {
        throw AuthException(
          'Biometric authentication not available',
          type: AuthErrorType.biometricsNotAvailable,
        );
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Enable biometric login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!authenticated) {
        throw AuthException(
          'Biometric verification failed',
          type: AuthErrorType.biometricsFailed,
        );
      }

      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw AuthException(
          'User not logged in',
          type: AuthErrorType.invalidSession,
        );
      }

      // Save biometric credentials
      await Future.wait([
        _secureStorage.write(key: 'biometric_email', value: currentUser.email),
        _secureStorage.write(key: 'biometric_device_id', value: (await _getDeviceInfo())['deviceId']),
        _prefs.setBool('biometrics_enabled', true),
      ]);

    } catch (e) {
      _errorTracker.recordError();
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to enable biometrics: ${e.toString()}',
        type: AuthErrorType.unknown,
      );
    }
  }

  Future<void> disableBiometrics() async {
    try {
      // Clear biometric credentials
      await Future.wait([
        _secureStorage.delete(key: 'biometric_email'),
        _secureStorage.delete(key: 'biometric_device_id'),
        _prefs.setBool('biometrics_enabled', false),
      ]);
    } catch (e) {
      _errorTracker.recordError();
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to disable biometrics: ${e.toString()}',
        type: AuthErrorType.unknown,
      );
    }
  }

  LoginResponse _handleLoginResponse(Map<String, dynamic> response) {
    final token = response['accessToken'] as String?;
    final refreshToken = response['refreshToken'] as String?;
    final roleStr = response['role'] as String?;
    final user = response['user'] as Map<String, dynamic>?;

    if (token == null || refreshToken == null || user == null) {
      throw AuthException(
        'Invalid response format from server',
        type: AuthErrorType.serverError,
        errorData: response,
      );
    }

    final loginResponse = LoginResponse(
      id: user['id'] as String,
      firstName: user['firstName'] as String,
      email: user['email'] as String,
      token: token,
      refreshToken: refreshToken,
      isEmailVerified: user['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: user['isPhoneVerified'] as bool? ?? false,
      role: roleStr != null ? _parseUserRole(roleStr) : UserRole.member,
      requiresMfa: response['requiresMfa'] as bool? ?? false,
      mfaPendingId: response['mfaPendingId'] as String?,
    );

    return loginResponse;
  }

  Future<void> updateProfile(User user) async {
    try {
      final currentToken = await token;
      if (currentToken == null) {
        throw AuthException(
          'Not authenticated',
          type: AuthErrorType.invalidSession,
        );
      }

      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw AuthException(
          'User not found',
          type: AuthErrorType.invalidSession,
        );
      }

      // Check if email is being changed
      if (user.email != currentUser.email && !currentUser.hasPermission('update_email')) {
        throw AuthException(
          'You do not have permission to change email',
          type: AuthErrorType.invalidSession,
        );
      }

      final response = await post<Map<String, dynamic>>(
        path: ApiConfig.updateProfile,
        parser: (json) => json,
        token: currentToken,
        body: user.toJson(),
      );

      if (response['user'] != null) {
        final updatedUser = User.fromJson(response['user'] as Map<String, dynamic>);
        await _saveUser(updatedUser);

        // If email was updated, start verification process
        if (user.email != currentUser.email) {
          await _sendEmailVerification(user.email);
        }
        return;
      }

      throw AuthException(
        response['message'] as String? ?? 'Failed to update profile',
        type: _mapUpdateErrorType(response),
        errorData: response,
      );
    } catch (e) {
      _errorTracker.recordError();
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to update profile: ${e.toString()}',
        type: AuthErrorType.unknown,
      );
    }
  }

  AuthErrorType _mapUpdateErrorType(Map<String, dynamic>? response) {
    final statusCode = response?['statusCode'] as int? ?? 500;
    
    switch (statusCode) {
      case 400:
        return AuthErrorType.invalidCredentials;
      case 401:
        return AuthErrorType.sessionExpired;
      case 403:
        return AuthErrorType.invalidSession;
      case 409:
        return AuthErrorType.accountDisabled;
      default:
        return AuthErrorType.unknown;
    }
  }

  AuthErrorType _mapRegistrationErrorType(Map<String, dynamic>? response) {
    final statusCode = response?['statusCode'] as int? ?? 500;
    final errorCode = response?['errorCode'] as String?;
    
    if (errorCode != null) {
      switch (errorCode) {
        case 'email_exists':
          return AuthErrorType.emailAlreadyExists;
        case 'username_exists':
          return AuthErrorType.usernameAlreadyExists;
        case 'invalid_password':
          return AuthErrorType.invalidPassword;
        case 'invalid_email':
          return AuthErrorType.invalidEmail;
        case 'invalid_username':
          return AuthErrorType.invalidUsername;
      }
    }
    
    switch (statusCode) {
      case 400:
        return AuthErrorType.invalidCredentials;
      case 409:
        return AuthErrorType.registrationError;
      case 422:
        return AuthErrorType.validationError;
      case 429:
        return AuthErrorType.tooManyAttempts;
      case 503:
        return AuthErrorType.serviceUnavailable;
      default:
        return AuthErrorType.serverError;
    }
  }

  Future<void> _sendEmailVerification(String email) async {
    try {
      final response = await post<Map<String, dynamic>>(
        path: ApiConfig.verifyEmail,
        parser: (json) => json,
        body: {'email': email},
      );

      if (response['success'] != true) {
        throw AuthException(
          response['message'] as String? ?? 'Failed to send verification email',
          type: AuthErrorType.unknown,
          errorData: response,
        );
      }
    } catch (e) {
      _errorTracker.recordError();
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to send verification email: ${e.toString()}',
        type: AuthErrorType.unknown,
      );
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      final response = await post<Map<String, dynamic>>(
        path: ApiConfig.resetPassword,
        parser: (json) => json,
        body: {'email': email},
      );

      // Handle successful response
      if (response['success'] == true) {
        return;
      }

      // Map error response to appropriate type
      final statusCode = response['statusCode'] as int? ?? 500;
      final errorType = statusCode == 404 ? AuthErrorType.invalidCredentials
        : statusCode == 429 ? AuthErrorType.tooManyAttempts
        : AuthErrorType.unknown;

      throw AuthException(
        response['message'] as String? ?? 'Failed to reset password',
        type: errorType,
        errorData: response,
        retryAfter: statusCode == 429 ? const Duration(minutes: 30) : null,
      );
    } on SocketException {
      _errorTracker.recordError();
      throw AuthException(
        'No internet connection',
        type: AuthErrorType.networkError,
      );
    } on FormatException {
      _errorTracker.recordError();
      throw AuthException(
        'Invalid response format',
        type: AuthErrorType.unknown,
      );
    } catch (e) {
      _errorTracker.recordError();
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to reset password: ${e.toString()}',
        type: AuthErrorType.unknown,
      );
    }
  }

  Future<void> verifyPhone({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final currentToken = await token;
      final response = await post<Map<String, dynamic>>(
        path: ApiConfig.verifyPhone,
        parser: (json) => json,
        token: currentToken,
        body: {
          'phoneNumber': phoneNumber,
          'otp': otp,
        },
      );

      if (response['success'] == true) {
        // If user is logged in, update their cached data
        if (isAuthenticated) {
          final currentUser = await getCurrentUser();
          if (currentUser != null) {
            final updatedUser = currentUser.copyWith(
              phoneNumber: phoneNumber,
              isPhoneVerified: true,
            );
            await _saveUser(updatedUser);
          }
        }
        return;
      }

      // Map error response to appropriate type
      final statusCode = response['statusCode'] as int? ?? 500;
      final errorType = statusCode == 400 ? AuthErrorType.invalidCredentials
        : statusCode == 404 ? AuthErrorType.accountDisabled
        : statusCode == 410 ? AuthErrorType.sessionExpired
        : statusCode == 429 ? AuthErrorType.tooManyAttempts
        : AuthErrorType.unknown;

      throw AuthException(
        response['message'] as String? ?? 'Phone verification failed',
        type: errorType,
        errorData: response,
        retryAfter: statusCode == 429 ? const Duration(minutes: 30) : null,
      );
    } catch (e) {
      _errorTracker.recordError();
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to verify phone: ${e.toString()}',
        type: AuthErrorType.unknown,
      );
    }
  }

  Future<void> updateBiometrics({required bool enabled}) async {
    try {
      final currentToken = await token;
      if (currentToken == null) {
        throw AuthException(
          'Not authenticated',
          type: AuthErrorType.invalidSession,
        );
      }

      if (enabled) {
        final canAuthenticate = await _localAuth.canCheckBiometrics;
        if (!canAuthenticate) {
          throw AuthException(
            'Biometric authentication not available',
            type: AuthErrorType.biometricsNotAvailable,
          );
        }

        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Enable biometric authentication',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (!authenticated) {
          throw AuthException(
            'Biometric verification failed',
            type: AuthErrorType.biometricsFailed,
          );
        }
      }

      final response = await post<Map<String, dynamic>>(
        path: ApiConfig.biometrics,
        parser: (json) => json,
        token: currentToken,
        body: {
          'enabled': enabled,
          if (enabled) 'deviceInfo': await _getDeviceInfo(),
        },
      );

      if (response['success'] == true) {
        await _prefs.setBool('biometrics_enabled', enabled);
        return;
      }

      throw AuthException(
        response['message'] as String? ?? 'Failed to update biometric settings',
        type: _mapUpdateErrorType(response),
        errorData: response,
      );
    } catch (e) {
      _errorTracker.recordError();
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to update biometric settings: ${e.toString()}',
        type: AuthErrorType.unknown,
      );
    }
  }

  Future<void> verifyPasswordReset(String token, String newPassword) async {
    try {
      if (!_isValidPassword(newPassword)) {
        final validationError = _validatePasswordStrength(newPassword);
        throw _createAuthError(
          validationError ?? 'Invalid password format',
          type: AuthErrorType.invalidPassword,
        );
      }

      final response = await post<Map<String, dynamic>>(
        path: '${ApiConfig.resetPassword}/verify',
        parser: (json) => json,
        body: {
          'token': token,
          'password': newPassword,
        },
      );

      // Check for success response
      if (response['success'] == true) {
        return;
      }

      final statusCode = response['statusCode'] as int? ?? 500;
      final errorType = statusCode == 400 ? AuthErrorType.invalidToken
        : statusCode == 422 ? AuthErrorType.invalidCredentials
        : AuthErrorType.unknown;

      throw AuthException(
        response['message'] as String? ?? 'Failed to reset password',
        type: errorType,
        errorData: response,
      );
    } catch (e) {
      _errorTracker.recordError();
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to verify password reset: ${e.toString()}',
        type: AuthErrorType.unknown,
      );
    }
  }

  bool _isValidPassword(String password) {
    // At least 8 characters long
    if (password.length < 8) return false;

    // Contains at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) return false;

    // Contains at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) return false;

    // Contains at least one number
    if (!password.contains(RegExp(r'[0-9]'))) return false;

    // Contains at least one special character
    if (!password.contains(RegExp(r'[!@#\$%\^&\*\(\)\-_\+=\[\]{};:,\.<>?~]'))) return false;

    // No repeating characters more than 3 times
    if (RegExp(r'(.)\1{3,}').hasMatch(password)) return false;

    // No common patterns or sequences
    final commonPatterns = [
      r'12345', r'qwerty', r'password', r'admin', r'welcome',
      r'abc123', r'123abc', r'test123', r'letmein', r'monkey'
    ];
    
    final passwordLower = password.toLowerCase();
    if (commonPatterns.any((pattern) => passwordLower.contains(pattern))) return false;

    return true;
  }

  String? _validatePasswordStrength(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!password.contains(RegExp(r'[!@#\$%\^&\*\(\)\-_\+=\[\]{};:,\.<>?~]'))) {
      return 'Password must contain at least one special character';
    }
    if (RegExp(r'(.)\1{3,}').hasMatch(password)) {
      return 'Password cannot contain repeating characters (more than 3 times)';
    }
    
    final commonPatterns = [
      r'12345', r'qwerty', r'password', r'admin', r'welcome',
      r'abc123', r'123abc', r'test123', r'letmein', r'monkey'
    ];
    
    final passwordLower = password.toLowerCase();
    if (commonPatterns.any((pattern) => passwordLower.contains(pattern))) {
      return 'Password contains a common pattern that is not allowed';
    }

    return null;
  }
}
