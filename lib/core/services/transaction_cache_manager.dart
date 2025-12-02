import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/transaction_goal.dart';

class TransactionCacheManager {
  static const String _transactionCacheKey = 'transaction_cache';
  static const String _goalsCacheKey = 'goals_cache';
  static const Duration _cacheValidity = Duration(minutes: 15);

  final SharedPreferences _prefs;

  TransactionCacheManager(this._prefs);

  static const int _maxCacheSize = 5 * 1024 * 1024; // 5MB
  static const String _cacheVersion = '1.0.0';

  Future<void> cacheTransactions(List<Transaction> transactions) async {
    try {
      final cache = {
        'version': _cacheVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'data': transactions.map((t) => t.toMap()).toList(),
      };
      
      final encodedCache = jsonEncode(cache);
      if (encodedCache.length > _maxCacheSize) {
        // If cache is too large, only store the most recent transactions
        final reducedTransactions = transactions.take(100).toList();
        final reducedCache = {
          'version': _cacheVersion,
          'timestamp': DateTime.now().toIso8601String(),
          'data': reducedTransactions.map((t) => t.toMap()).toList(),
        };
        await _prefs.setString(_transactionCacheKey, jsonEncode(reducedCache));
      } else {
        await _prefs.setString(_transactionCacheKey, encodedCache);
      }
    } catch (e) {
      // If caching fails, clear the cache to prevent inconsistencies
      await clearCache();
      rethrow;
    }
  }

  Future<List<Transaction>?> getCachedTransactions() async {
    try {
      final cacheJson = _prefs.getString(_transactionCacheKey);
      if (cacheJson == null) return null;

      final cache = jsonDecode(cacheJson) as Map<String, dynamic>;
      
      // Check cache version
      final version = cache['version'] as String?;
      if (version != _cacheVersion) {
        await clearCache();
        return null;
      }

      final timestamp = DateTime.parse(cache['timestamp'] as String);
      
      if (DateTime.now().difference(timestamp) > _cacheValidity) {
        await _prefs.remove(_transactionCacheKey);
        return null;
      }

      return (cache['data'] as List)
          .map((t) => Transaction.fromMap(t as Map<String, dynamic>))
          .toList();
    } catch (e) {
      await clearCache();
      return null;
    }
  }

  Future<void> cacheTransactionGoals(List<TransactionGoal> goals) async {
    try {
      final cache = {
        'version': _cacheVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'data': goals.map((g) => g.toMap()).toList(),
      };

      final encodedCache = jsonEncode(cache);
      if (encodedCache.length > _maxCacheSize) {
        // If cache is too large, only store the most recent goals
        final reducedGoals = goals.take(50).toList();
        final reducedCache = {
          'version': _cacheVersion,
          'timestamp': DateTime.now().toIso8601String(),
          'data': reducedGoals.map((g) => g.toMap()).toList(),
        };
        await _prefs.setString(_goalsCacheKey, jsonEncode(reducedCache));
      } else {
        await _prefs.setString(_goalsCacheKey, encodedCache);
      }
    } catch (e) {
      await clearCache();
      rethrow;
    }
  }

  Future<List<TransactionGoal>?> getCachedGoals() async {
    try {
      final cacheJson = _prefs.getString(_goalsCacheKey);
      if (cacheJson == null) return null;

      final cache = jsonDecode(cacheJson) as Map<String, dynamic>;
      
      // Check cache version
      final version = cache['version'] as String?;
      if (version != _cacheVersion) {
        await clearCache();
        return null;
      }

      final timestamp = DateTime.parse(cache['timestamp'] as String);
      
      if (DateTime.now().difference(timestamp) > _cacheValidity) {
        await _prefs.remove(_goalsCacheKey);
        return null;
      }

      return (cache['data'] as List)
          .map((g) => TransactionGoal.fromMap(g as Map<String, dynamic>))
          .toList();
    } catch (e) {
      await clearCache();
      return null;
    }
  }

  Future<void> clearCache() async {
    await Future.wait([
      _prefs.remove(_transactionCacheKey),
      _prefs.remove(_goalsCacheKey),
    ]);
  }
}
