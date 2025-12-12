import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  // Store secure data
  static Future<void> saveSecure(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Retrieve secure data
  static Future<String?> getSecure(String key) async {
    return await _storage.read(key: key);
  }

  // Delete secure data
  static Future<void> deleteSecure(String key) async {
    await _storage.delete(key: key);
  }

  // Delete all secure data
  static Future<void> deleteAllSecure() async {
    await _storage.deleteAll();
  }

  // Check if a key exists
  static Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  // Get all secure keys
  static Future<Map<String, String>> getAllSecure() async {
    return await _storage.readAll();
  }

  // Store multiple values securely
  static Future<void> saveMultipleSecure(Map<String, String> items) async {
    await Future.wait(
      items.entries.map(
        (entry) => _storage.write(
          key: entry.key,
          value: entry.value,
        ),
      ),
    );
  }

  // Delete multiple values
  static Future<void> deleteMultipleSecure(List<String> keys) async {
    await Future.wait(
      keys.map((key) => _storage.delete(key: key)),
    );
  }
}
