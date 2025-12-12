import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class StorageService {
  static const String _transactionsBox = 'transactions';
  static const String _documentsBox = 'documents';
  static const String _userBox = 'user';
  static const String _settingsBox = 'settings';

  Future<void> initialize() async {
    final directory = await getApplicationDocumentsDirectory();
    Hive.init(directory.path);

    await Future.wait([
      Hive.openBox(_transactionsBox),
      Hive.openBox(_documentsBox),
      Hive.openBox(_userBox),
      Hive.openBox(_settingsBox),
    ]);
  }

  // Transactions
  Future<void> cacheTransactions(List<Map<String, dynamic>> transactions) async {
    final box = await Hive.openBox(_transactionsBox);
    await box.clear();
    await box.addAll(transactions);
  }

  Future<List<Map<String, dynamic>>> getCachedTransactions() async {
    final box = await Hive.openBox(_transactionsBox);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Documents
  Future<void> cacheDocuments(List<Map<String, dynamic>> documents) async {
    final box = await Hive.openBox(_documentsBox);
    await box.clear();
    await box.addAll(documents);
  }

  Future<List<Map<String, dynamic>>> getCachedDocuments() async {
    final box = await Hive.openBox(_documentsBox);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // User Data
  Future<void> cacheUserData(Map<String, dynamic> userData) async {
    final box = await Hive.openBox(_userBox);
    await box.put('userData', userData);
  }

  Future<Map<String, dynamic>?> getCachedUserData() async {
    final box = await Hive.openBox(_userBox);
    final userData = await box.get('userData');
    return userData != null ? Map<String, dynamic>.from(userData) : null;
  }

  // Settings
  Future<void> saveSetting(String key, dynamic value) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put(key, value);
  }

  Future<dynamic> getSetting(String key) async {
    final box = await Hive.openBox(_settingsBox);
    return box.get(key);
  }

  // File Cache
  Future<void> cacheFile(String key, File file) async {
    final directory = await getApplicationDocumentsDirectory();
    final cachePath = '${directory.path}/cache';
    await Directory(cachePath).create(recursive: true);

    final extension = file.path.split('.').last;
    final cachedFile = File('$cachePath/$key.$extension');
    await file.copy(cachedFile.path);

    final box = await Hive.openBox(_settingsBox);
    await box.put('file_$key', cachedFile.path);
  }

  Future<File?> getCachedFile(String key) async {
    final box = await Hive.openBox(_settingsBox);
    final filePath = await box.get('file_$key');
    if (filePath != null) {
      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }
    }
    return null;
  }

  // Cache Management
  Future<void> clearCache() async {
    await Future.wait([
      Hive.deleteBoxFromDisk(_transactionsBox),
      Hive.deleteBoxFromDisk(_documentsBox),
      Hive.deleteBoxFromDisk(_userBox),
      Hive.deleteBoxFromDisk(_settingsBox),
    ]);

    final directory = await getApplicationDocumentsDirectory();
    final cachePath = '${directory.path}/cache';
    final cacheDir = Directory(cachePath);
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }

  // Sync Status
  Future<void> markAsSynced(String key) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('sync_$key', DateTime.now().toIso8601String());
  }

  Future<DateTime?> getLastSyncTime(String key) async {
    final box = await Hive.openBox(_settingsBox);
    final syncTime = await box.get('sync_$key');
    return syncTime != null ? DateTime.parse(syncTime) : null;
  }

  // Data Compression
  Future<void> compressAndCacheData(String key, Map<String, dynamic> data) async {
    // TODO: Implement data compression before caching
  }

  Future<Map<String, dynamic>?> getCompressedData(String key) async {
    // TODO: Implement data decompression after retrieval
    return null;
  }
}
