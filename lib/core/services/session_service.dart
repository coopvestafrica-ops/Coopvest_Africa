import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:synchronized/synchronized.dart';

class SessionService {
  static const _tokenKey = 'auth_token';
  static const _sessionTimeoutKey = 'session_timeout';
  static const _lastActivityKey = 'last_activity';
  
  final FlutterSecureStorage _storage;
  final Lock _lock = Lock();
  Timer? _sessionTimer;
  bool _isActive = false;
  final _sessionTimeoutController = StreamController<void>.broadcast();

  // Default session timeout of 30 minutes
  static const int defaultSessionTimeout = 30;

  SessionService({FlutterSecureStorage? storage}) 
      : _storage = storage ?? const FlutterSecureStorage();

  Stream<void> get onSessionTimeout => _sessionTimeoutController.stream;

  Future<void> initialize() async {
    await _lock.synchronized(() async {
      final lastActivity = await _storage.read(key: _lastActivityKey);
      final timeout = await getSessionTimeout();
      
      if (lastActivity != null) {
        final lastActivityTime = DateTime.parse(lastActivity);
        final now = DateTime.now();
        final difference = now.difference(lastActivityTime).inMinutes;
        
        if (difference >= timeout) {
          await endSession();
        } else {
          _startSessionTimer(timeout);
          _isActive = true;
        }
      }
    });
  }

  Future<void> startSession(String token) async {
    await _lock.synchronized(() async {
      await _storage.write(key: _tokenKey, value: token);
      await updateLastActivity();
      final timeout = await getSessionTimeout();
      _startSessionTimer(timeout);
      _isActive = true;
    });
  }

  Future<void> endSession() async {
    await _lock.synchronized(() async {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _lastActivityKey);
      _stopSessionTimer();
      _isActive = false;
      _sessionTimeoutController.add(null);
    });
  }

  Future<void> updateLastActivity() async {
    if (!_isActive) return;
    
    await _lock.synchronized(() async {
      await _storage.write(
        key: _lastActivityKey,
        value: DateTime.now().toIso8601String(),
      );
      
      final timeout = await getSessionTimeout();
      _restartSessionTimer(timeout);
    });
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> setSessionTimeout(int minutes) async {
    await _storage.write(
      key: _sessionTimeoutKey,
      value: minutes.toString(),
    );
    
    if (_isActive) {
      _restartSessionTimer(minutes);
    }
  }

  Future<int> getSessionTimeout() async {
    final timeout = await _storage.read(key: _sessionTimeoutKey);
    return timeout != null ? int.parse(timeout) : defaultSessionTimeout;
  }

  void _startSessionTimer(int timeoutMinutes) {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(Duration(minutes: timeoutMinutes), () {
      endSession();
    });
  }

  void _restartSessionTimer(int timeoutMinutes) {
    _startSessionTimer(timeoutMinutes);
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  Future<bool> isSessionActive() async {
    final token = await getAuthToken();
    final lastActivity = await _storage.read(key: _lastActivityKey);
    
    if (token == null || lastActivity == null) {
      return false;
    }

    final lastActivityTime = DateTime.parse(lastActivity);
    final now = DateTime.now();
    final timeout = await getSessionTimeout();
    
    return now.difference(lastActivityTime).inMinutes < timeout;
  }

  void dispose() {
    _stopSessionTimer();
    _sessionTimeoutController.close();
  }
}
