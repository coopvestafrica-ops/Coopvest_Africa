import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('MMM d, yyyy HH:mm');

  static String format(String date, {bool includeTime = false}) {
    try {
      final DateTime dateTime = DateTime.parse(date);
      return includeTime 
          ? _dateTimeFormat.format(dateTime)
          : _dateFormat.format(dateTime);
    } catch (_) {
      return date;
    }
  }
}
