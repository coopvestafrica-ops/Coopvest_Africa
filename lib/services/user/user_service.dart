import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../models/user_model.dart';
import '../api/api_client.dart';

/// User service for backend synchronization and profile management
class UserService extends ChangeNotifier {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  UserModel? _currentUser;
  bool _isLoading = false;

  static const String _userCacheKey = 'cached_user';

  UserService({
    required ApiClient apiClient,
    required SharedPreferences prefs,
  })  : _apiClient = apiClient,
        _prefs = prefs;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get hasUser => _currentUser != null;

  /// Initialize user service by loading cached user
  Future<void> initialize() async {
    try {
      AppLogger.info('Initializing UserService');
      await _loadCachedUser();
      AppLogger.info('UserService initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize UserService', e);
    }
  }

  /// Fetch user profile from backend
  Future<UserModel> fetchUserProfile(String userId) async {
    try {
      _setLoading(true);
      AppLogger.info('Fetching user profile for userId: $userId');

      final response = await _apiClient.get<Map<String, dynamic>>(
        endpoint: '/api/users/$userId',
      );

      final user = UserModel.fromJson(response);
      _currentUser = user;

      // Cache user data
      await _cacheUser(user);

      notifyListeners();
      AppLogger.info('User profile fetched successfully');
      return user;
    } catch (e) {
      AppLogger.error('Failed to fetch user profile', e);
      throw ErrorHandler.handleException(e);
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<UserModel> updateUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? bio,
    String? profilePictureUrl,
  }) async {
    try {
      _setLoading(true);
      AppLogger.info('Updating user profile for userId: $userId');

      final updateData = <String, dynamic>{
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (bio != null) 'bio': bio,
        if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
      };

      final response = await _apiClient.put<Map<String, dynamic>>(
        endpoint: '/api/users/$userId',
        data: updateData,
      );

      final updatedUser = UserModel.fromJson(response);
      _currentUser = updatedUser;

      // Cache updated user data
      await _cacheUser(updatedUser);

      notifyListeners();
      AppLogger.info('User profile updated successfully');
      return updatedUser;
    } catch (e) {
      AppLogger.error('Failed to update user profile', e);
      throw ErrorHandler.handleException(e);
    } finally {
      _setLoading(false);
    }
  }

  /// Sync user with backend after Firebase authentication
  Future<UserModel> syncUserWithBackend({
    required String firebaseUid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      _setLoading(true);
      AppLogger.info('Syncing user with backend');

      // Parse display name into first and last name
      String firstName = '';
      String lastName = '';

      if (displayName != null && displayName.isNotEmpty) {
        final parts = displayName.split(' ');
        firstName = parts.first;
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }

      final syncData = {
        'firebase_uid': firebaseUid,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'profile_picture_url': photoUrl,
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        endpoint: '/api/users/sync',
        data: syncData,
      );

      final user = UserModel.fromJson(response);
      _currentUser = user;

      // Cache user data
      await _cacheUser(user);

      notifyListeners();
      AppLogger.info('User synced with backend successfully');
      return user;
    } catch (e) {
      AppLogger.error('Failed to sync user with backend', e);
      throw ErrorHandler.handleException(e);
    } finally {
      _setLoading(false);
    }
  }

  /// Update last login timestamp
  Future<void> updateLastLogin(String userId) async {
    try {
      AppLogger.info('Updating last login for userId: $userId');

      await _apiClient.patch<Map<String, dynamic>>(
        endpoint: '/api/users/$userId/last-login',
      );

      AppLogger.info('Last login updated');
    } catch (e) {
      AppLogger.error('Failed to update last login', e);
      // Don't throw - this is not critical
    }
  }

  /// Verify user email
  Future<void> verifyUserEmail(String userId) async {
    try {
      AppLogger.info('Verifying user email for userId: $userId');

      await _apiClient.patch<Map<String, dynamic>>(
        endpoint: '/api/users/$userId/verify-email',
      );

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(isVerified: true);
        await _cacheUser(_currentUser!);
        notifyListeners();
      }

      AppLogger.info('User email verified');
    } catch (e) {
      AppLogger.error('Failed to verify user email', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Clear current user
  Future<void> clearUser() async {
    try {
      AppLogger.info('Clearing current user');
      _currentUser = null;
      await _prefs.remove(_userCacheKey);
      notifyListeners();
      AppLogger.info('Current user cleared');
    } catch (e) {
      AppLogger.error('Failed to clear user', e);
    }
  }

  /// Load cached user from local storage
  Future<void> _loadCachedUser() async {
    try {
      final userJson = _prefs.getString(_userCacheKey);
      if (userJson != null) {
        // Parse JSON string to map
        final Map<String, dynamic> userMap = Map.from(
          (userJson as dynamic) is String
              ? {'data': userJson}
              : userJson as Map<String, dynamic>,
        );
        _currentUser = UserModel.fromJson(userMap);
        AppLogger.debug('Cached user loaded');
      }
    } catch (e) {
      AppLogger.warning('Failed to load cached user', e);
    }
  }

  /// Cache user to local storage
  Future<void> _cacheUser(UserModel user) async {
    try {
      final userJson = user.toJson();
      // Store as JSON string
      await _prefs.setString(_userCacheKey, userJson.toString());
      AppLogger.debug('User cached locally');
    } catch (e) {
      AppLogger.warning('Failed to cache user', e);
    }
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Get user info for debugging
  Map<String, dynamic>? getUserInfo() {
    if (_currentUser == null) return null;

    return {
      'id': _currentUser!.id,
      'email': _currentUser!.email,
      'fullName': _currentUser!.fullName,
      'isVerified': _currentUser!.isVerified,
      'isActive': _currentUser!.isActive,
      'createdAt': _currentUser!.createdAt.toString(),
    };
  }
}
