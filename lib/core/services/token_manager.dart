import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// A service to manage authentication tokens securely.
class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  static TokenManager get instance => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenTypeKey = 'token_type';

  // Token refresh configuration
  static const Duration _refreshThreshold = Duration(minutes: 5);
  Timer? _refreshTimer;

  // Token change stream
  final _tokenController = StreamController<TokenStatus>.broadcast();
  Stream<TokenStatus> get tokenStream => _tokenController.stream;

  TokenManager._internal();

  /// Stores both access and refresh tokens securely
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
    String tokenType = 'Bearer',
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _tokenTypeKey, value: tokenType),
    ]);

    _startRefreshTimer(accessToken);
    _tokenController.add(TokenStatus(
      isValid: true,
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
    ));
  }

  /// Gets the stored access token
  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  /// Gets the stored refresh token
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  /// Gets the token type (e.g., 'Bearer')
  Future<String?> getTokenType() async {
    return _storage.read(key: _tokenTypeKey);
  }

  /// Gets the complete authorization header value
  Future<String?> getAuthorizationHeader() async {
    final accessToken = await getAccessToken();
    final tokenType = await getTokenType();
    
    if (accessToken == null || tokenType == null) return null;
    return '$tokenType $accessToken';
  }

  /// Checks if there is a valid, non-expired access token
  Future<bool> hasValidToken() async {
    try {
      final token = await getAccessToken();
      if (token == null) return false;

      final decodedToken = JwtDecoder.decode(token);
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(
        decodedToken['exp'] * 1000,
      );
      
      return DateTime.now().isBefore(expirationDate);
    } catch (e) {
      return false;
    }
  }

  /// Gets the expiration date of the access token
  Future<DateTime?> getTokenExpiration() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;

      final decodedToken = JwtDecoder.decode(token);
      return DateTime.fromMillisecondsSinceEpoch(
        decodedToken['exp'] * 1000,
      );
    } catch (e) {
      return null;
    }
  }

  /// Gets the claims from the access token
  Future<Map<String, dynamic>?> getTokenClaims() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;

      return JwtDecoder.decode(token);
    } catch (e) {
      return null;
    }
  }

  /// Checks if the token needs to be refreshed soon
  Future<bool> needsRefresh() async {
    try {
      final expiration = await getTokenExpiration();
      if (expiration == null) return true;

      final threshold = DateTime.now().add(_refreshThreshold);
      return threshold.isAfter(expiration);
    } catch (e) {
      return true;
    }
  }

  /// Clears all stored tokens
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _tokenTypeKey),
    ]);

    _stopRefreshTimer();
    _tokenController.add(TokenStatus(isValid: false));
  }

  /// Starts the refresh timer for the access token
  void _startRefreshTimer(String accessToken) {
    _stopRefreshTimer();

    try {
      final decodedToken = JwtDecoder.decode(accessToken);
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(
        decodedToken['exp'] * 1000,
      );
      
      final timeUntilRefresh = expirationDate
          .subtract(_refreshThreshold)
          .difference(DateTime.now());

      if (timeUntilRefresh.isNegative) return;

      _refreshTimer = Timer(timeUntilRefresh, () {
        _tokenController.add(TokenStatus(
          isValid: true,
          needsRefresh: true,
          accessToken: accessToken,
        ));
      });
    } catch (e) {
      // Invalid token format, don't start timer
    }
  }

  /// Stops the refresh timer
  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Disposes of the token manager resources
  void dispose() {
    _stopRefreshTimer();
    _tokenController.close();
  }

  /// Securely wipes all stored tokens and encryption keys
  Future<void> secureWipe() async {
    try {
      // First, overwrite the tokens with random data
      final random = List.generate(64, (_) => '0123456789ABCDEF'[DateTime.now().microsecond % 16]).join();
      
      await Future.wait([
        _storage.write(key: _accessTokenKey, value: random),
        _storage.write(key: _refreshTokenKey, value: random),
        _storage.write(key: _tokenTypeKey, value: random),
      ]);

      // Then delete the overwritten data
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _tokenTypeKey),
      ]);

      _stopRefreshTimer();
      _tokenController.add(TokenStatus(isValid: false));
    } catch (e) {
      // If secure wipe fails, fall back to normal clear
      await clearTokens();
    }
  }
}

/// Represents the current status of authentication tokens
class TokenStatus {
  /// Whether the tokens are valid
  final bool isValid;
  
  /// Whether the access token needs to be refreshed
  final bool needsRefresh;
  
  /// The current access token (if available)
  final String? accessToken;
  
  /// The current refresh token (if available)
  final String? refreshToken;
  
  /// The token type (e.g., 'Bearer')
  final String? tokenType;

  TokenStatus({
    required this.isValid,
    this.needsRefresh = false,
    this.accessToken,
    this.refreshToken,
    this.tokenType,
  });
}
