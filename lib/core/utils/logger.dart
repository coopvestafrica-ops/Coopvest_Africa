class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  void debug(String message, [dynamic data]) {
    _log('DEBUG', message, data);
  }

  void info(String message, [dynamic data]) {
    _log('INFO', message, data);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('ERROR', message, error, stackTrace);
  }

  void warn(String message, [dynamic data]) {
    _log('WARN', message, data);
  }

  void _log(String level, String message, [dynamic data, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '$timestamp [$level] $message';

    if (data != null) {
      print('$logMessage\nData: $data');
    } else {
      print(logMessage);
    }

    if (stackTrace != null) {
      print('StackTrace:\n$stackTrace');
    }
  }
}
