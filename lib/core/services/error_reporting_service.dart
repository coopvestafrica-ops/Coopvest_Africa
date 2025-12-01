import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Error reporting service for managing crash logs and error tracking
/// 
/// Supports both Firebase Crashlytics (production) and local logging (debug)
/// 
/// Features:
/// - ✅ Firebase Crashlytics integration
/// - ✅ Stack trace capture
/// - ✅ User context tracking
/// - ✅ Custom error logging
/// - ✅ Error statistics
/// - ✅ Graceful degradation (works without Crashlytics)
class ErrorReportingService {
  static final ErrorReportingService _instance = ErrorReportingService._internal();

  factory ErrorReportingService() {
    return _instance;
  }

  ErrorReportingService._internal();

  static ErrorReportingService get instance => _instance;

  bool _isInitialized = false;
  bool _crashlyticsEnabled = false;
  
  // Error statistics tracking
  int _totalErrorsReported = 0;
  int _crashesReported = 0;
  final Map<String, int> _errorTypeCount = {};

  // Getters
  bool get isInitialized => _isInitialized;
  bool get crashlyticsEnabled => _crashlyticsEnabled;
  int get totalErrorsReported => _totalErrorsReported;
  int get crashesReported => _crashesReported;
  Map<String, int> get errorTypeCount => Map.unmodifiable(_errorTypeCount);

  /// Initialize error reporting service
  /// Call this during app startup
  Future<void> initialize({
    bool enableCrashlytics = true,
    bool captureStackTraces = true,
  }) async {
    try {
      // Configure Firebase Crashlytics
      if (enableCrashlytics && !kIsWeb) {
        // Only initialize Crashlytics on mobile platforms
        FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        
        // Pass all uncaught exceptions to Crashlytics
        FlutterError.onError = (FlutterErrorDetails details) {
          FirebaseCrashlytics.instance.recordFlutterError(details);
        };

        _crashlyticsEnabled = true;
        debugPrint('✅ Firebase Crashlytics initialized');
      }

      _isInitialized = true;
      debugPrint('✅ Error reporting service initialized');
    } catch (e) {
      debugPrint('⚠️ Error initializing Crashlytics: $e');
      // Continue without Crashlytics if it fails
    }
  }

  /// Report an exception to Crashlytics
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   // Some code
  /// } catch (e, stackTrace) {
  ///   ErrorReportingService.instance.reportException(
  ///     e,
  ///     stackTrace,
  ///     reason: 'Failed to fetch user data',
  ///     fatal: false,
  ///   );
  /// }
  /// ```
  Future<void> reportException(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? context,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ ErrorReportingService not initialized');
      return;
    }

    try {
      _totalErrorsReported++;
      
      // Track error type
      final errorType = exception.runtimeType.toString();
      _errorTypeCount[errorType] = (_errorTypeCount[errorType] ?? 0) + 1;

      // Log locally
      debugPrint('❌ Exception: $exception');
      if (stackTrace != null) {
        debugPrint('Stack trace:\n$stackTrace');
      }
      if (reason != null) {
        debugPrint('Reason: $reason');
      }

      // Report to Crashlytics in production
      if (_crashlyticsEnabled && !kDebugMode) {
        if (context != null) {
          // Set custom keys for context
          for (final entry in context.entries) {
            FirebaseCrashlytics.instance.setCustomKey(
              entry.key,
              entry.value.toString(),
            );
          }
        }

        if (reason != null) {
          FirebaseCrashlytics.instance.setCustomKey('reason', reason);
        }

        await FirebaseCrashlytics.instance.recordError(
          exception,
          stackTrace,
          fatal: fatal,
          reason: reason,
        );

        if (fatal) {
          _crashesReported++;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error reporting exception: $e');
    }
  }

  /// Report a message (non-fatal)
  /// 
  /// Example:
  /// ```dart
  /// ErrorReportingService.instance.reportMessage(
  ///   'User logged in successfully',
  ///   level: 'info',
  /// );
  /// ```
  Future<void> reportMessage(
    String message, {
    String level = 'info', // 'debug', 'info', 'warning', 'error'
  }) async {
    if (!_isInitialized) {
      return;
    }

    try {
      _totalErrorsReported++;

      // Log locally
      debugPrint('ℹ️ [$level] $message');

      // Report to Crashlytics
      if (_crashlyticsEnabled && !kDebugMode) {
        FirebaseCrashlytics.instance.log('[$level] $message');
      }
    } catch (e) {
      debugPrint('⚠️ Error reporting message: $e');
    }
  }

  /// Set user context for crash reports
  /// 
  /// Example:
  /// ```dart
  /// ErrorReportingService.instance.setUserContext(
  ///   userId: user.id,
  ///   email: user.email,
  ///   customData: {'role': 'admin'},
  /// );
  /// ```
  Future<void> setUserContext({
    required String userId,
    String? email,
    String? displayName,
    Map<String, dynamic>? customData,
  }) async {
    if (!_isInitialized) {
      return;
    }

    try {
      if (_crashlyticsEnabled && !kDebugMode) {
        // Set Crashlytics user ID
        await FirebaseCrashlytics.instance.setUserIdentifier(userId);

        // Set custom keys for user data
        FirebaseCrashlytics.instance.setCustomKey('userId', userId);
        
        if (email != null) {
          FirebaseCrashlytics.instance.setCustomKey('email', email);
        }
        
        if (displayName != null) {
          FirebaseCrashlytics.instance.setCustomKey('displayName', displayName);
        }

        if (customData != null) {
          for (final entry in customData.entries) {
            FirebaseCrashlytics.instance.setCustomKey(
              'user_${entry.key}',
              entry.value.toString(),
            );
          }
        }
      }

      debugPrint('✅ User context set: $userId');
    } catch (e) {
      debugPrint('⚠️ Error setting user context: $e');
    }
  }

  /// Clear user context (on logout)
  /// 
  /// Example:
  /// ```dart
  /// ErrorReportingService.instance.clearUserContext();
  /// ```
  Future<void> clearUserContext() async {
    if (!_isInitialized) {
      return;
    }

    try {
      if (_crashlyticsEnabled && !kDebugMode) {
        // Clear Crashlytics user ID
        FirebaseCrashlytics.instance.setUserIdentifier('');
      }

      debugPrint('✅ User context cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing user context: $e');
    }
  }

  /// Report custom error with context
  /// 
  /// Example:
  /// ```dart
  /// ErrorReportingService.instance.reportCustomError(
  ///   'API_ERROR',
  ///   'Failed to fetch user profile',
  ///   context: {
  ///     'endpoint': '/api/users/123',
  ///     'statusCode': 500,
  ///   },
  /// );
  /// ```
  Future<void> reportCustomError(
    String errorCode,
    String description, {
    Map<String, dynamic>? context,
    bool fatal = false,
  }) async {
    if (!_isInitialized) {
      return;
    }

    try {
      _totalErrorsReported++;
      _errorTypeCount[errorCode] = (_errorTypeCount[errorCode] ?? 0) + 1;

      debugPrint('❌ Custom Error: $errorCode - $description');
      if (context != null) {
        debugPrint('Context: $context');
      }

      if (_crashlyticsEnabled && !kDebugMode) {
        FirebaseCrashlytics.instance.setCustomKey('errorCode', errorCode);
        FirebaseCrashlytics.instance.setCustomKey('description', description);

        if (context != null) {
          for (final entry in context.entries) {
            FirebaseCrashlytics.instance.setCustomKey(
              entry.key,
              entry.value.toString(),
            );
          }
        }

        await FirebaseCrashlytics.instance.recordError(
          Exception(errorCode),
          null,
          fatal: fatal,
          reason: description,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error reporting custom error: $e');
    }
  }

  /// Get error statistics
  /// 
  /// Example:
  /// ```dart
  /// final stats = ErrorReportingService.instance.getStatistics();
  /// print('Total errors: ${stats['totalErrors']}');
  /// ```
  Map<String, dynamic> getStatistics() {
    return {
      'totalErrors': _totalErrorsReported,
      'crashes': _crashesReported,
      'errorTypes': _errorTypeCount,
      'crashlyticsEnabled': _crashlyticsEnabled,
      'initialized': _isInitialized,
    };
  }

  /// Reset statistics (useful for testing)
  void resetStatistics() {
    _totalErrorsReported = 0;
    _crashesReported = 0;
    _errorTypeCount.clear();
    debugPrint('✅ Error statistics reset');
  }

  /// Dispose and cleanup resources
  Future<void> dispose() async {
    debugPrint('✅ Error reporting service disposed');
  }
}

/// Global error handler for use in main()
/// 
/// Usage:
/// ```dart
/// PlatformDispatcher.instance.onError = globalErrorHandler;
/// ```
bool globalErrorHandler(Object error, StackTrace stack) {
  debugPrint('🔴 Platform Error: $error');
  debugPrint('Stack trace:\n$stack');
  
  ErrorReportingService.instance.reportException(
    error,
    stack,
    reason: 'Platform error',
    fatal: true,
  );
  
  return true; // Prevent app crash
}
