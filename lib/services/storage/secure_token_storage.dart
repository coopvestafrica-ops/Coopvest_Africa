import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/utils/logger.dart';

/// Secure storage for authentication tokens
class SecureTokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userIdKey = 'user_id';

  final FlutterSecureStorage _storage;

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
      AppLogger.debug('Access token saved securely');
    } catch (e) {
      AppLogger.error('Failed to save access token', e);
      throw CacheException(
        message: 'Failed to save access token',
        originalException: e,
      );
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(key: _accessTokenKey);
      AppLogger.debug('Access token retrieved');
      return token;
    } catch (e) {
      AppLogger.error('Failed to retrieve access token', e);
      throw CacheException(
        message: 'Failed to retrieve access token',
        originalException: e,
      );
    }
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
      AppLogger.debug('Refresh token saved securely');
    } catch (e) {
      AppLogger.error('Failed to save refresh token', e);
      throw CacheException(
        message: 'Failed to save refresh token',
        originalException: e,
      );
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      final token = await _storage.read(key: _refreshTokenKey);
      AppLogger.debug('Refresh token retrieved');
      return token;
    } catch (e) {
      AppLogger.error('Failed to retrieve refresh token', e);
      throw CacheException(
        message: 'Failed to retrieve refresh token',
        originalException: e,
      );
    }
  }

  /// Save token expiry time
  Future<void> saveTokenExpiry(DateTime expiry) async {
    try {
      await _storage.write(
        key: _tokenExpiryKey,
        value: expiry.toIso8601String(),
      );
      AppLogger.debug('Token expiry saved');
    } catch (e) {
      AppLogger.error('Failed to save token expiry', e);
      throw CacheException(
        message: 'Failed to save token expiry',
        originalException: e,
      );
    }
  }

  /// Get token expiry time
  Future<DateTime?> getTokenExpiry() async {
    try {
      final expiryString = await _storage.read(key: _tokenExpiryKey);
      if (expiryString == null) return null;
      return DateTime.parse(expiryString);
    } catch (e) {
      AppLogger.error('Failed to retrieve token expiry', e);
      throw CacheException(
        message: 'Failed to retrieve token expiry',
        originalException: e,
      );
    }
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    try {
      final expiry = await getTokenExpiry();
      if (expiry == null) return true;
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      AppLogger.error('Failed to check token expiry', e);
      return true;
    }
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
      AppLogger.debug('User ID saved');
    } catch (e) {
      AppLogger.error('Failed to save user ID', e);
      throw CacheException(
        message: 'Failed to save user ID',
        originalException: e,
      );
    }
  }

  /// Get user ID
  Future<String?> getUserId() async {
    try {
      final userId = await _storage.read(key: _userIdKey);
      AppLogger.debug('User ID retrieved');
      return userId;
    } catch (e) {
      AppLogger.error('Failed to retrieve user ID', e);
      throw CacheException(
        message: 'Failed to retrieve user ID',
        originalException: e,
      );
    }
  }

  /// Save all tokens and user data
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiry,
    required String userId,
  }) async {
    try {
      await Future.wait([
        saveAccessToken(accessToken),
        saveRefreshToken(refreshToken),
        saveTokenExpiry(expiry),
        saveUserId(userId),
      ]);
      AppLogger.info('All tokens saved successfully');
    } catch (e) {
      AppLogger.error('Failed to save all tokens', e);
      rethrow;
    }
  }

  /// Clear all tokens
  Future<void> clearAllTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _tokenExpiryKey),
        _storage.delete(key: _userIdKey),
      ]);
      AppLogger.info('All tokens cleared');
    } catch (e) {
      AppLogger.error('Failed to clear tokens', e);
      throw CacheException(
        message: 'Failed to clear tokens',
        originalException: e,
      );
    }
  }

  /// Check if tokens exist
  Future<bool> hasTokens() async {
    try {
      final accessToken = await getAccessToken();
      return accessToken != null && accessToken.isNotEmpty;
    } catch (e) {
      AppLogger.error('Failed to check if tokens exist', e);
      return false;
    }
  }
}
