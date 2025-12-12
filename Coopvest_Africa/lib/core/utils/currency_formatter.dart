import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _nairaFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );

  static String format(double amount) {
    return _nairaFormat.format(amount);
  }

  static double? parse(String text) {
    try {
      return _nairaFormat.parse(text).toDouble();
    } catch (e) {
      return null;
    }
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return '₦${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '₦${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return format(amount);
    }
  }
}
