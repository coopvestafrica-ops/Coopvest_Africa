import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_item.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _notificationsKey = 'notifications';
  final SharedPreferences _prefs;
  List<NotificationItem> _notifications = [];

  NotificationProvider(this._prefs) {
    _loadNotifications();
  }
  List<NotificationItem> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _loadNotifications() {
    final String? notificationsJson = _prefs.getString(_notificationsKey);
    if (notificationsJson != null) {
      final List<dynamic> decodedList = json.decode(notificationsJson);
      _notifications = decodedList
          .map((item) => NotificationItem.fromMap(item))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    }
  }

  Future<void> _saveNotifications() async {
    final String encodedList = json.encode(
      _notifications.map((item) => item.toMap()).toList(),
    );
    await _prefs.setString(_notificationsKey, encodedList);
  }

  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);
    _saveNotifications();
    notifyListeners();
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].isRead = true;
      _saveNotifications();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    _saveNotifications();
    notifyListeners();
  }

  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _saveNotifications();
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _saveNotifications();
    notifyListeners();
  }
}
