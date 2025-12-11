import 'dart:async';
import 'dart:io' show stderr, Platform;
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/firebase_options.dart';


/// Service class to handle all Firebase related operations
class FirebaseService {
    static FirebaseService? _instance;
    static final Logger _logger = Logger('FirebaseService');
    static Logger get logger => _logger;

    static StreamSubscription<LogRecord>? _logSubscription;

    /// Helper method to format log messages
    static String _formatMessage(String message) {
      return message.replaceAll('\n', '\n${' ' * 36}'); // Align multiline messages
    }

    /// Helper method to indent text blocks
    static String _indentText(String text) {
      return text.split('\n').map((line) => '${' ' * 4}$line').join('\n');
    }

    /// Helper method to add color to log levels
    static String _getColoredLevel(Level level, String text) {
      final colorCode = switch (level) {
        Level.SEVERE => '31', // Red
        Level.WARNING => '33', // Yellow
        Level.INFO => '32', // Green
        Level.FINE => '36', // Cyan
        Level.FINER => '34', // Blue
        Level.FINEST => '35', // Magenta
        _ => '37', // White
      };
      return '\x1B[${colorCode}m$text\x1B[0m';
    }

    // Initialize logging configuration
    static void _initializeLogging() {
      hierarchicalLoggingEnabled = true;
      Logger.root.level = Level.INFO;

      // Cancel existing subscription if any
      _logSubscription?.cancel();

      // Create new subscription
      _logSubscription = Logger.root.onRecord.listen((record) {
        // Format timestamp
        final time = record.time.toLocal().toString().padRight(26);

        // Format log level with color and padding
        final levelName = record.level.name.padRight(7);
        final level = _getColoredLevel(record.level, levelName);

        // Format source (logger name) with padding for alignment
        final source = record.loggerName.padRight(15);

        // Format message with proper indentation for multiline messages
        final message = _formatMessage(record.message);

        // Format error and stack trace with proper indentation
        final error = record.error != null ? '\n${_indentText('ERROR: ${record.error}')}' : '';
        final stackTrace = record.stackTrace != null ? '\n${_indentText(record.stackTrace.toString())}' : '';

        // Build the formatted log message
        final logMessage = '$time $level $source $message$error$stackTrace';

        // Print to console based on log level
        switch (record.level) {
          case Level.SEVERE:
            stderr.writeln('\x1B[31m$logMessage\x1B[0m'); // Red for errors
            break;
          case Level.WARNING:
            stderr.writeln('\x1B[33m$logMessage\x1B[0m'); // Yellow for warnings
            break;
          default:
            debugPrint(logMessage);
            break;
        }
      });
    }

    /// Singleton instance getter
    static FirebaseService get instance {
      if (_instance == null) {
        _initializeLogging();
        _instance = FirebaseService._();
      }
      return _instance!;
    }

    // Private constructor
    FirebaseService._();

    late final FirebaseFirestore _firestore;
    late final FirebaseAuth _auth;
    late final FirebaseStorage _storage;
    late final FirebaseMessaging _messaging;

    bool _isInitialized = false;

    // Getters for Firebase instances with initialization checks
    FirebaseFirestore get firestore {
      _checkInitialization();
      return _firestore;
    }

    FirebaseAuth get auth {
      _checkInitialization();
      return _auth;
    }

    FirebaseStorage get storage {
      _checkInitialization();
      return _storage;
    }

    FirebaseMessaging get messaging {
      _checkInitialization();
      return _messaging;
    }

    /// Checks if Firebase is initialized
    void _checkInitialization() {
      if (!_isInitialized) {
        throw StateError('FirebaseService must be initialized before use. Call initialize() first.');
      }
    }

    bool get isInitialized => _isInitialized;

    /// Initialize Firebase services
    Future<void> initialize() async {
      try {
        if (_isInitialized) {
          _logger.info('Firebase already initialized');
          return;
        }

        _logger.info('Initializing Firebase...');

        // Initialize Firebase core with default options from firebase_options.dart
        final app = await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _logger.info('Initialized Firebase App: ${app.name}');

        // Initialize services with error handling
        try {
          _firestore = FirebaseFirestore.instance;
          await _initializeFirestore();
        } catch (e, stack) {
          _logger.severe('Failed to initialize Firestore', e, stack);
          rethrow;
        }

        try {
          _auth = FirebaseAuth.instance;
        } catch (e, stack) {
          _logger.severe('Failed to initialize Firebase Auth', e, stack);
          rethrow;
        }

        try {
          _storage = FirebaseStorage.instance;
        } catch (e, stack) {
          _logger.severe('Failed to initialize Firebase Storage', e, stack);
          rethrow;
        }

        try {
          _messaging = FirebaseMessaging.instance;
          await _configureMessaging();
        } catch (e, stack) {
          _logger.warning('Failed to initialize Firebase Messaging - continuing anyway', e, stack);
          // Don't rethrow as messaging is not critical
        }

        _isInitialized = true;
        _logger.info('Firebase initialized successfully');
      } catch (e, stack) {
        _logger.severe('Failed to initialize Firebase', e, stack);
        _isInitialized = false;
        rethrow;
      }
    }

    /// Initialize Firestore with settings and persistence
    Future<void> _initializeFirestore() async {
      try {
        // Enable network first
        await FirebaseFirestore.instance.enableNetwork();

        // Configure Firestore settings with persistence enabled
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );

        _logger.info('Firestore settings configured successfully');
      } catch (e, stack) {
        _logger.severe('Error configuring Firestore settings', e, stack);
        rethrow;
      }
    }

    /// Configure Firebase Cloud Messaging
    Future<void> _configureMessaging() async {
      try {
        // Request notification permissions
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
          criticalAlert: false,
          announcement: false,
          carPlay: false,
        );

        _logger.info('Notification permission status: ${settings.authorizationStatus}');

        // Get FCM token
        final token = await _messaging.getToken();

        // Save token to user document if logged in
        final user = _auth.currentUser;
        if (user != null && token != null) {
          await _updateFcmToken(user.uid, token);
        }

        // Handle token refresh
        _messaging.onTokenRefresh.listen(
          (String newToken) async {
            final currentUser = _auth.currentUser;
            if (currentUser != null) {
              await _updateFcmToken(currentUser.uid, newToken);
            }
          },
          onError: (error) {
            _logger.warning('Error in token refresh stream', error);
          },
          cancelOnError: false,
        );

      } catch (e, stack) {
        _logger.warning('Error configuring messaging', e, stack);
        // Don't rethrow as messaging is not critical
      }
    }

    /// Update FCM token for a user
    Future<void> _updateFcmToken(String userId, String token) async {
      try {
        final userDoc = _firestore.collection('users').doc(userId);

        await userDoc.set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'platform': Platform.operatingSystem,
          'appVersion': await _getAppVersion(),
        }, SetOptions(merge: true));

        _logger.info('FCM Token updated for user: $userId');
      } catch (e, stack) {
        _logger.warning('Failed to update FCM token for user: $userId', e, stack);
        // Don't rethrow as this is not critical
      }
    }

    /// Get current app version
    Future<String> _getAppVersion() async {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        return '${packageInfo.version}+${packageInfo.buildNumber}';
      } catch (e) {
        return 'unknown';
      }
    }

    // Collection references with strong typing
    CollectionReference<Map<String, dynamic>> get users =>
        _firestore.collection('users');

    CollectionReference<Map<String, dynamic>> get loans =>
        _firestore.collection('loans');

    CollectionReference<Map<String, dynamic>> get savings =>
        _firestore.collection('savings');

    CollectionReference<Map<String, dynamic>> get contributions =>
        _firestore.collection('contributions');

    CollectionReference<Map<String, dynamic>> get transactions =>
        _firestore.collection('transactions');

    CollectionReference<Map<String, dynamic>> get notifications =>
        _firestore.collection('notifications');

    /// Enable network for Firestore
    Future<void> enableNetwork() async {
      try {
        await _firestore.enableNetwork();
        _logger.info('Firestore network enabled');
      } catch (e, stack) {
        _logger.warning('Error enabling Firestore network', e, stack);
        rethrow;
      }
    }

    /// Disable network for Firestore
    Future<void> disableNetwork() async {
      try {
        await _firestore.disableNetwork();
        _logger.info('Firestore network disabled');
      } catch (e, stack) {
        _logger.warning('Error disabling Firestore network', e, stack);
        rethrow;
      }
    }

    /// Clear all cached data
    Future<void> clearCache() async {
      try {
        await _firestore.clearPersistence();
        _logger.info('Firestore cache cleared');
      } catch (e, stack) {
        _logger.warning('Error clearing Firestore cache', e, stack);
        rethrow;
      }
    }

    /// Terminate Firebase instance
    Future<void> terminate() async {
      try {
        await _firestore.terminate();
        _isInitialized = false;
        _logger.info('Firebase terminated');
      } catch (e, stack) {
        _logger.warning('Error terminating Firebase', e, stack);
        rethrow;
      } finally {
        // Clean up resources
        await cleanup();
      }
    }

    /// Clean up resources
    Future<void> cleanup() async {
      // Cancel log subscription
      await _logSubscription?.cancel();
      _logSubscription = null;

      // Clear instance
      _instance = null;
    }

    /// Dispose method
    Future<void> dispose() async {
      if (_isInitialized) {
        await terminate();
      }
      await cleanup();
    }
  }
