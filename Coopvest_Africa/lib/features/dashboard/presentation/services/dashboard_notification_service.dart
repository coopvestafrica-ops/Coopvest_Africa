import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DashboardNotificationService {
  static final DashboardNotificationService _instance = DashboardNotificationService._internal();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  int _notificationId = 0;
  bool _permissionsGranted = false;

  factory DashboardNotificationService() {
    return _instance;
  }

  DashboardNotificationService._internal() {
    // Reset notification ID daily to prevent overflow
    _resetNotificationIdDaily();
  }

  void _resetNotificationIdDaily() {
    Future.delayed(
      Duration(
        hours: 24 - DateTime.now().hour,
        minutes: 60 - DateTime.now().minute,
      ),
      () {
        _notificationId = 0;
        _resetNotificationIdDaily();
      },
    );
  }

  int _getNextNotificationId() {
    return _notificationId++;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Check notification permissions
      _permissionsGranted = true; // Default to true, will be updated based on actual notification delivery
          


      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      _permissionsGranted = false;
      debugPrint('Failed to initialize notifications: $e');
      // You might want to report this to an error tracking service
    }
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    // Handle notification tap here
    // You can navigate to specific screens based on the notification payload
  }

  Future<bool> showBalanceUpdateNotification({
    required String title,
    required String body,
    String? payload,
    int maxRetries = 3,
  }) async {
    try {
      await _ensureInitialized();
      if (!_isInitialized || !_permissionsGranted) {
        debugPrint('Notifications not initialized or permissions not granted');
        return false;
      }

      const androidDetails = AndroidNotificationDetails(
        'dashboard_updates',
        'Dashboard Updates',
        channelDescription: 'Notifications for dashboard updates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.active,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      int attempts = 0;
      while (attempts < maxRetries) {
        try {
          await _notifications.show(
            _getNextNotificationId(),
            title,
            body,
            details,
            payload: payload,
          );
          return true;
        } catch (e) {
          attempts++;
          if (attempts >= maxRetries) rethrow;
          await Future.delayed(Duration(seconds: attempts * 2)); // Exponential backoff
        }
      }
      return false;
    } catch (e) {
      debugPrint('Failed to show balance update notification: $e');
      return false;
    }
  }

  Future<void> showLoanUpdateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      'loan_updates',
      'Loan Updates',
      channelDescription: 'Notifications for loan status updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> showInvestmentUpdateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      'investment_updates',
      'Investment Updates',
      channelDescription: 'Notifications for investment updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}
