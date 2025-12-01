import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiCache {
  final SharedPreferences prefs;
  final Duration defaultTTL;
  static const String _timestampSuffix = '_timestamp';

  ApiCache({
    required this.prefs,
    this.defaultTTL = const Duration(minutes: 5),
  });

  Future<void> set(String key, dynamic value, {Duration? ttl}) async {
    final expiryTime = DateTime.now().add(ttl ?? defaultTTL);
    await prefs.setString(key, json.encode(value));
    await prefs.setString('$key$_timestampSuffix', expiryTime.toIso8601String());
  }

  T? get<T>(String key, T Function(Map<String, dynamic>) converter) {
    final timestampStr = prefs.getString('$key$_timestampSuffix');
    if (timestampStr == null) return null;

    final timestamp = DateTime.parse(timestampStr);
    if (timestamp.isBefore(DateTime.now())) {
      // Cache expired, clear it
      prefs.remove(key);
      prefs.remove('$key$_timestampSuffix');
      return null;
    }

    final value = prefs.getString(key);
    if (value == null) return null;

    try {
      final data = json.decode(value) as Map<String, dynamic>;
      return converter(data);
    } catch (e) {
      // Invalid cache data, clear it
      prefs.remove(key);
      prefs.remove('$key$_timestampSuffix');
      return null;
    }
  }

  Future<void> clear(String key) async {
    await prefs.remove(key);
    await prefs.remove('$key$_timestampSuffix');
  }

  Future<void> clearAll() async {
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.endsWith(_timestampSuffix)) {
        final baseKey = key.substring(0, key.length - _timestampSuffix.length);
        await clear(baseKey);
      }
    }
  }

  bool has(String key) {
    return prefs.containsKey(key) && 
           prefs.containsKey('$key$_timestampSuffix');
  }

  bool isExpired(String key) {
    final timestampStr = prefs.getString('$key$_timestampSuffix');
    if (timestampStr == null) return true;

    final timestamp = DateTime.parse(timestampStr);
    return timestamp.isBefore(DateTime.now());
  }
}
