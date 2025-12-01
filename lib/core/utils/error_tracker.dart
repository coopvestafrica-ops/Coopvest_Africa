import 'dart:collection';
import 'dart:developer' as developer;

/// Tracks and manages error occurrences with sophisticated rate limiting and blocking
class ErrorTracker {
  final int maxErrors;
  final Duration windowDuration;
  final Duration blockDuration;
  final Duration? customBlockDuration;
  final bool enableLogging;

  final Queue<_ErrorEntry> _errorTimes = Queue<_ErrorEntry>();
  DateTime? _blockUntil;
  final Map<String, int> _errorTypeCount = {};
  final Map<String, DateTime> _lastErrorOfType = {};

  ErrorTracker({
    required this.maxErrors,
    required this.windowDuration,
    Duration? blockDuration,
    this.customBlockDuration,
    this.enableLogging = true,
  }) : blockDuration = blockDuration ?? const Duration(minutes: 15);

  /// Records an error occurrence with optional error type and metadata
  void recordError({
    String? errorType,
    Map<String, dynamic>? metadata,
    Duration? customBlockDuration,
  }) {
    final now = DateTime.now();
    final entry = _ErrorEntry(
      timestamp: now,
      errorType: errorType,
      metadata: metadata,
    );

    _errorTimes.addLast(entry);
    _updateErrorTypeStats(errorType, now);

    // Remove errors outside the window
    _cleanOldErrors(now);

    // Check if we should start blocking
    if (_shouldStartBlocking()) {
      _blockUntil = now.add(customBlockDuration ?? blockDuration);
      if (enableLogging) {
        developer.log(
          'Request blocking activated',
          name: 'ErrorTracker',
          error: {
            'errorCount': _errorTimes.length,
            'blockDuration': (_blockUntil?.difference(now))?.inMinutes,
            'errorTypes': _errorTypeCount,
          },
        );
      }
    }
  }

  /// Returns whether requests should be blocked based on error history
  bool shouldBlockRequests() {
    if (_blockUntil != null) {
      if (DateTime.now().isAfter(_blockUntil!)) {
        _resetBlockingState();
        return false;
      }
      return true;
    }
    return _shouldStartBlocking();
  }

  /// Gets the remaining duration of the block if any
  Duration? getBlockDuration() {
    if (_blockUntil == null) return null;

    final remaining = _blockUntil!.difference(DateTime.now());
    if (remaining.isNegative) {
      _resetBlockingState();
      return null;
    }

    return remaining;
  }

  /// Gets error statistics for the current window
  Map<String, dynamic> getErrorStats() {
    final now = DateTime.now();
    _cleanOldErrors(now);

    return {
      'totalErrors': _errorTimes.length,
      'errorsByType': Map<String, int>.from(_errorTypeCount),
      'isBlocked': shouldBlockRequests(),
      'blockDuration': getBlockDuration()?.inMinutes,
      'errorFrequency': _calculateErrorFrequency(),
      'lastErrors': _getRecentErrors(),
    };
  }

  /// Gets the error rate for a specific type of error
  double getErrorRate(String errorType) {
    _cleanOldErrors(DateTime.now());

    final typeCount = _errorTypeCount[errorType] ?? 0;
    if (typeCount == 0) return 0.0;

    final windowInMinutes = windowDuration.inMinutes;
    return typeCount / windowInMinutes;
  }

  /// Checks if a specific error type has exceeded its rate limit
  bool hasExceededTypeLimit(String errorType, int maxErrorsOfType) {
    return (_errorTypeCount[errorType] ?? 0) >= maxErrorsOfType;
  }

  /// Gets time until a specific error type can be retried
  Duration? getRetryAfterForType(String errorType) {
    final lastError = _lastErrorOfType[errorType];
    if (lastError == null) return null;

    final now = DateTime.now();
    final timeSinceLastError = now.difference(lastError);

    // Use AuthErrorType-specific retry delays
    final retryDelay = _getRetryDelayForErrorType(errorType);

    final remainingTime = retryDelay - timeSinceLastError;
    return remainingTime.isNegative ? null : remainingTime;
  }

  /// Clears all error tracking data
  void clear() {
    _errorTimes.clear();
    _errorTypeCount.clear();
    _lastErrorOfType.clear();
    _blockUntil = null;
  }

  // Private helper methods

  void _cleanOldErrors(DateTime now) {
    // Remove old errors and update type counts
    while (_errorTimes.isNotEmpty &&
        now.difference(_errorTimes.first.timestamp) > windowDuration) {
      final oldError = _errorTimes.removeFirst();
      if (oldError.errorType != null) {
        _errorTypeCount[oldError.errorType!] =
            (_errorTypeCount[oldError.errorType!] ?? 1) - 1;

        if (_errorTypeCount[oldError.errorType!] == 0) {
          _errorTypeCount.remove(oldError.errorType!);
          _lastErrorOfType.remove(oldError.errorType!);
        }
      }
    }
  }

  bool _shouldStartBlocking() {
    return _errorTimes.length >= maxErrors;
  }

  void _resetBlockingState() {
    _blockUntil = null;
    _errorTimes.clear();
    _errorTypeCount.clear();
    _lastErrorOfType.clear();
  }

  void _updateErrorTypeStats(String? errorType, DateTime timestamp) {
    if (errorType != null) {
      _errorTypeCount[errorType] = (_errorTypeCount[errorType] ?? 0) + 1;
      _lastErrorOfType[errorType] = timestamp;
    }
  }

  Duration _getRetryDelayForErrorType(String errorType) {
    // Map error types to appropriate retry delays
    switch (errorType) {
      case 'AuthErrorType.tooManyAttempts':
        return const Duration(minutes: 30);
      case 'AuthErrorType.securityAlert':
        return const Duration(hours: 1);
      case 'AuthErrorType.networkError':
        return const Duration(seconds: 30);
      case 'AuthErrorType.serverError':
        return const Duration(minutes: 5);
      default:
        return const Duration(minutes: 15);
    }
  }

  double _calculateErrorFrequency() {
    if (_errorTimes.isEmpty) return 0.0;

    final windowMinutes = windowDuration.inMinutes;
    final errorCount = _errorTimes.length;

    return errorCount / windowMinutes;
  }

  List<Map<String, dynamic>> _getRecentErrors() {
    return _errorTimes
        .take(5)
        .map((error) => {
              'type': error.errorType,
              'timestamp': error.timestamp.toIso8601String(),
              'metadata': error.metadata,
            })
        .toList();
  }
}

/// Represents a single error occurrence with metadata
class _ErrorEntry {
  final DateTime timestamp;
  final String? errorType;
  final Map<String, dynamic>? metadata;

  _ErrorEntry({
    required this.timestamp,
    this.errorType,
    this.metadata,
  });
}
