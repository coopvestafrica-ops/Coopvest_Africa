import 'package:flutter/foundation.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/utils/logger.dart';
import 'secure_token_storage.dart';

/// Manages token lifecycle including refresh and expiration
class TokenManager extends ChangeNotifier {
  final SecureTokenStorage _storage;

  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  String? _userId;

  // Token refresh threshold (refresh token 5 minutes before expiry)
  static const Duration _refreshThreshold = Duration(minutes: 5);

  TokenManager({SecureTokenStorage? storage})
      : _storage = storage ?? SecureTokenStorage();

  // Getters
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  DateTime? get tokenExpiry => _tokenExpiry;
  String? get userId => _userId;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  /// Initialize token manager by loading tokens from storage
  Future<void> initialize() async {
    try {
      AppLogger.info('Initializing TokenManager');
      _accessToken = await _storage.getAccessToken();
      _refreshToken = await _storage.getRefreshToken();
      _tokenExpiry = await _storage.getTokenExpiry();
      _userId = await _storage.getUserId();
      notifyListeners();
      AppLogger.info('TokenManager initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize TokenManager', e);
      rethrow;
    }
  }

  /// Set tokens after authentication
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiry,
    required String userId,
  }) async {
    try {
      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _tokenExpiry = expiry;
      _userId = userId;

      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiry: expiry,
        userId: userId,
      );

      notifyListeners();
      AppLogger.info('Tokens set successfully');
    } catch (e) {
      AppLogger.error('Failed to set tokens', e);
      rethrow;
    }
  }

  /// Update access token (used during token refresh)
  Future<void> updateAccessToken({
    required String accessToken,
    required DateTime expiry,
  }) async {
    try {
      _accessToken = accessToken;
      _tokenExpiry = expiry;

      await _storage.saveAccessToken(accessToken);
      await _storage.saveTokenExpiry(expiry);

      notifyListeners();
      AppLogger.info('Access token updated');
    } catch (e) {
      AppLogger.error('Failed to update access token', e);
      rethrow;
    }
  }

  /// Check if token needs refresh
  bool shouldRefreshToken() {
    if (_tokenExpiry == null) return false;

    final now = DateTime.now();
    final refreshTime = _tokenExpiry!.subtract(_refreshThreshold);

    return now.isAfter(refreshTime);
  }

  /// Check if token is expired
  bool isTokenExpired() {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!);
  }

  /// Get time until token expiry
  Duration? getTimeUntilExpiry() {
    if (_tokenExpiry == null) return null;
    final duration = _tokenExpiry!.difference(DateTime.now());
    return duration.isNegative ? Duration.zero : duration;
  }

  /// Clear all tokens
  Future<void> clearTokens() async {
    try {
      _accessToken = null;
      _refreshToken = null;
      _tokenExpiry = null;
      _userId = null;

      await _storage.clearAllTokens();
      notifyListeners();
      AppLogger.info('All tokens cleared');
    } catch (e) {
      AppLogger.error('Failed to clear tokens', e);
      rethrow;
    }
  }

  /// Validate token format (basic JWT validation)
  static bool isValidToken(String? token) {
    if (token == null || token.isEmpty) return false;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      // Basic validation - JWT should have 3 parts separated by dots
      for (var part in parts) {
        if (part.isEmpty) return false;
      }

      return true;
    } catch (e) {
      AppLogger.warning('Invalid token format', e);
      return false;
    }
  }

  /// Get token info (for debugging)
  Map<String, dynamic> getTokenInfo() {
    return {
      'hasAccessToken': _accessToken != null,
      'hasRefreshToken': _refreshToken != null,
      'isExpired': isTokenExpired(),
      'shouldRefresh': shouldRefreshToken(),
      'expiryTime': _tokenExpiry?.toString(),
      'timeUntilExpiry': getTimeUntilExpiry()?.toString(),
      'userId': _userId,
    };
  }
}
