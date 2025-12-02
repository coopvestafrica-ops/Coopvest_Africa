class DateUtils {
  /// Returns a new [DateTime] with the time portion set to midnight
  static DateTime dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Returns true if the given dates are on the same day
  static bool isSameDay(DateTime dateTime1, DateTime dateTime2) {
    return dateTime1.year == dateTime2.year &&
           dateTime1.month == dateTime2.month &&
           dateTime1.day == dateTime2.day;
  }

  /// Returns the start of the month for the given date
  static DateTime startOfMonth(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month);
  }

  /// Returns the end of the month for the given date
  static DateTime endOfMonth(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month + 1, 0, 23, 59, 59);
  }

  /// Returns the number of days in the month for the given date
  static int daysInMonth(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month + 1, 0).day;
  }

  /// Returns a list of [DateTime] objects for each day between start and end
  static List<DateTime> getDaysInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = dateOnly(start);
    final endDate = dateOnly(end);

    while (current.isBefore(endDate) || isSameDay(current, endDate)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }

    return days;
  }
}
