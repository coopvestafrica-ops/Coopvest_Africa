import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  final SharedPreferences _prefs;
  static const String _pinKey = 'user_pin';
  static const String _biometricEnabledKey = 'biometric_enabled';

  LocalAuthService(this._prefs);

  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<void> setPin(String pin) async {
    // In a production app, you should hash the PIN before storing
    await _prefs.setString(_pinKey, pin);
  }

  Future<bool> verifyPin(String pin) async {
    final storedPin = _prefs.getString(_pinKey);
    return storedPin == pin;
  }

  Future<void> enableBiometric(bool enable) async {
    await _prefs.setBool(_biometricEnabledKey, enable);
  }

  bool isBiometricEnabled() {
    return _prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> resetSecuritySettings() async {
    await Future.wait([
      _prefs.remove(_pinKey),
      _prefs.remove(_biometricEnabledKey),
    ]);
  }
}
