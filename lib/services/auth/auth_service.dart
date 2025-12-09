import 'package:flutter/foundation.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../models/user_model.dart';
import '../storage/token_manager.dart';
import '../user/user_service.dart';
import 'firebase_auth_service.dart';

/// Main authentication service orchestrating Firebase and backend
class AuthService extends ChangeNotifier {
  final FirebaseAuthService _firebaseAuth;
  final TokenManager _tokenManager;
  final UserService _userService;

  bool _isLoading = false;
  String? _error;

  AuthService({
    required FirebaseAuthService firebaseAuth,
    required TokenManager tokenManager,
    required UserService userService,
  })  : _firebaseAuth = firebaseAuth,
        _tokenManager = tokenManager,
        _userService = userService;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _tokenManager.isAuthenticated;
  String? get currentUserId => _tokenManager.userId;
  UserModel? get currentUser => _userService.currentUser;

  /// Initialize auth service
  Future<void> initialize() async {
    try {
      AppLogger.info('Initializing AuthService');
      await _tokenManager.initialize();
      await _userService.initialize();
      AppLogger.info('AuthService initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize AuthService', e);
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      AppLogger.info('Starting sign up process');

      // Create Firebase user
      final firebaseUser = await _firebaseAuth.signUp(
        email: email,
        password: password,
      );

      AppLogger.info('Firebase user created: ${firebaseUser.user?.uid}');

      // Get ID token from Firebase
      final idToken = await _firebaseAuth.getIdToken();
      if (idToken == null) {
        throw AuthException(
          message: 'Failed to get authentication token',
          code: 'NO_ID_TOKEN',
        );
      }

      // Sync user with backend
      final user = await _userService.syncUserWithBackend(
        firebaseUid: firebaseUser.user!.uid,
        email: email,
        displayName: '$firstName $lastName',
      );

      // Store tokens
      await _tokenManager.setTokens(
        accessToken: idToken,
        refreshToken: firebaseUser.user!.uid, // Use UID as refresh token placeholder
        expiry: DateTime.now().add(const Duration(hours: 1)),
        userId: user.id,
      );

      notifyListeners();
      AppLogger.info('Sign up completed successfully');
      return user;
    } catch (e) {
      AppLogger.error('Sign up failed', e);
      _setError(ErrorHandler.handleException(e).message);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      AppLogger.info('Starting sign in process');

      // Sign in with Firebase
      final firebaseUser = await _firebaseAuth.signIn(
        email: email,
        password: password,
      );

      AppLogger.info('Firebase sign in successful: ${firebaseUser.user?.uid}');

      // Get ID token
      final idToken = await _firebaseAuth.getIdToken();
      if (idToken == null) {
        throw AuthException(
          message: 'Failed to get authentication token',
          code: 'NO_ID_TOKEN',
        );
      }

      // Fetch user profile from backend
      final user = await _userService.fetchUserProfile(firebaseUser.user!.uid);

      // Store tokens
      await _tokenManager.setTokens(
        accessToken: idToken,
        refreshToken: firebaseUser.user!.uid,
        expiry: DateTime.now().add(const Duration(hours: 1)),
        userId: user.id,
      );

      // Update last login
      await _userService.updateLastLogin(user.id);

      notifyListeners();
      AppLogger.info('Sign in completed successfully');
      return user;
    } catch (e) {
      AppLogger.error('Sign in failed', e);
      _setError(ErrorHandler.handleException(e).message);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();
      AppLogger.info('Starting sign out process');

      await _firebaseAuth.signOut();
      await _tokenManager.clearTokens();
      await _userService.clearUser();

      notifyListeners();
      AppLogger.info('Sign out completed successfully');
    } catch (e) {
      AppLogger.error('Sign out failed', e);
      _setError(ErrorHandler.handleException(e).message);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _clearError();
      AppLogger.info('Sending password reset email');

      await _firebaseAuth.sendPasswordResetEmail(email);

      AppLogger.info('Password reset email sent');
    } catch (e) {
      AppLogger.error('Failed to send password reset email', e);
      _setError(ErrorHandler.handleException(e).message);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? bio,
    String? profilePictureUrl,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      AppLogger.info('Updating user profile');

      if (currentUser == null) {
        throw AuthException(
          message: 'No user logged in',
          code: 'NO_USER',
        );
      }

      final updatedUser = await _userService.updateUserProfile(
        userId: currentUser!.id,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        bio: bio,
        profilePictureUrl: profilePictureUrl,
      );

      notifyListeners();
      AppLogger.info('User profile updated successfully');
      return updatedUser;
    } catch (e) {
      AppLogger.error('Failed to update profile', e);
      _setError(ErrorHandler.handleException(e).message);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh authentication token
  Future<void> refreshToken() async {
    try {
      AppLogger.info('Refreshing authentication token');

      if (!_tokenManager.shouldRefreshToken()) {
        AppLogger.debug('Token refresh not needed');
        return;
      }

      final newIdToken = await _firebaseAuth.getIdToken(forceRefresh: true);
      if (newIdToken == null) {
        throw TokenException(
          message: 'Failed to refresh token',
          code: 'REFRESH_FAILED',
        );
      }

      await _tokenManager.updateAccessToken(
        accessToken: newIdToken,
        expiry: DateTime.now().add(const Duration(hours: 1)),
      );

      AppLogger.info('Token refreshed successfully');
    } catch (e) {
      AppLogger.error('Failed to refresh token', e);
      // If token refresh fails, sign out user
      await signOut();
      rethrow;
    }
  }

  /// Check authentication status
  Future<bool> checkAuthStatus() async {
    try {
      AppLogger.info('Checking authentication status');

      if (!isAuthenticated) {
        AppLogger.info('User is not authenticated');
        return false;
      }

      // Check if token is expired
      if (_tokenManager.isTokenExpired()) {
        AppLogger.warning('Token is expired');
        await signOut();
        return false;
      }

      // Refresh token if needed
      if (_tokenManager.shouldRefreshToken()) {
        await refreshToken();
      }

      AppLogger.info('User is authenticated');
      return true;
    } catch (e) {
      AppLogger.error('Failed to check auth status', e);
      return false;
    }
  }

  /// Get authentication info for debugging
  Map<String, dynamic> getAuthInfo() {
    return {
      'isAuthenticated': isAuthenticated,
      'currentUserId': currentUserId,
      'tokenInfo': _tokenManager.getTokenInfo(),
      'userInfo': _userService.getUserInfo(),
    };
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _error = null;
  }
}
