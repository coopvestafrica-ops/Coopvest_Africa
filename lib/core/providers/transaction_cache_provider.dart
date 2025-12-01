import 'package:shared_preferences/shared_preferences.dart';
import '../services/transaction_cache_manager.dart';

class TransactionCacheProvider {
  static TransactionCacheManager? _instance;

  static Future<TransactionCacheManager> get instance async {
    _instance ??= TransactionCacheManager(await SharedPreferences.getInstance());
    return _instance!;
  }
}
