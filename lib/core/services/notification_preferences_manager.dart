import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreference {
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final bool defaultValue;

  const NotificationPreference({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    this.defaultValue = true,
  });
}

class QuietHours {
  final TimeOfDay start;
  final TimeOfDay end;
  final bool enabled;

  const QuietHours({
    required this.start,
    required this.end,
    required this.enabled,
  });

  Map<String, dynamic> toJson() => {
        'startHour': start.hour,
        'startMinute': start.minute,
        'endHour': end.hour,
        'endMinute': end.minute,
        'enabled': enabled,
      };

  factory QuietHours.fromJson(Map<String, dynamic> json) {
    return QuietHours(
      start: TimeOfDay(hour: json['startHour'], minute: json['startMinute']),
      end: TimeOfDay(hour: json['endHour'], minute: json['endMinute']),
      enabled: json['enabled'],
    );
  }

  factory QuietHours.defaults() {
    return QuietHours(
      start: const TimeOfDay(hour: 22, minute: 0), // 10:00 PM
      end: const TimeOfDay(hour: 7, minute: 0), // 7:00 AM
      enabled: false,
    );
  }
}

class NotificationPreferencesManager {
  static const notifications = [
    NotificationPreference(
      key: 'transaction_alerts',
      title: 'Transaction Alerts',
      description: 'Get notified about deposits, withdrawals, and transfers',
      icon: Icons.account_balance_wallet,
    ),
    NotificationPreference(
      key: 'loan_updates',
      title: 'Loan Updates',
      description: 'Updates about loan applications, approvals, and repayments',
      icon: Icons.monetization_on,
    ),
    NotificationPreference(
      key: 'investment_updates',
      title: 'Investment Updates',
      description: 'Notifications about investment opportunities and returns',
      icon: Icons.trending_up,
    ),
    NotificationPreference(
      key: 'savings_reminders',
      title: 'Savings Reminders',
      description: 'Reminders about savings goals and contributions',
      icon: Icons.savings,
    ),
    NotificationPreference(
      key: 'security_alerts',
      title: 'Security Alerts',
      description: 'Important security updates and suspicious activity alerts',
      icon: Icons.security,
      defaultValue: true,
    ),
    NotificationPreference(
      key: 'document_updates',
      title: 'Document Updates',
      description: 'Status updates about document verification',
      icon: Icons.description,
    ),
    NotificationPreference(
      key: 'meeting_reminders',
      title: 'Meeting Reminders',
      description: 'Reminders about upcoming cooperative meetings',
      icon: Icons.event,
    ),
    NotificationPreference(
      key: 'marketing_notifications',
      title: 'Marketing Notifications',
      description: 'Promotions, offers, and news about our services',
      icon: Icons.campaign,
      defaultValue: false,
    ),
  ];

  static const _quietHoursKey = 'quiet_hours';
  static const _emailNotificationsKey = 'email_notifications';
  static const _smsNotificationsKey = 'sms_notifications';

  final SharedPreferences _prefs;

  NotificationPreferencesManager._(this._prefs);

  static Future<NotificationPreferencesManager> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferencesManager._(prefs);
  }

  Future<bool> getPreference(String key) async {
    final preference = notifications.firstWhere((p) => p.key == key);
    return _prefs.getBool(key) ?? preference.defaultValue;
  }

  Future<void> setPreference(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  Future<Map<String, bool>> getAllPreferences() async {
    final Map<String, bool> preferences = {};
    for (var notification in notifications) {
      preferences[notification.key] = await getPreference(notification.key);
    }
    return preferences;
  }

  Future<QuietHours> getQuietHours() async {
    final json = _prefs.getString(_quietHoursKey);
    if (json == null) {
      return QuietHours.defaults();
    }
    return QuietHours.fromJson(Map<String, dynamic>.from(
      const JsonDecoder().convert(json),
    ));
  }

  Future<void> setQuietHours(QuietHours quietHours) async {
    await _prefs.setString(
      _quietHoursKey,
      const JsonEncoder().convert(quietHours.toJson()),
    );
  }

  Future<bool> isEmailEnabled() async {
    return _prefs.getBool(_emailNotificationsKey) ?? true;
  }

  Future<void> setEmailEnabled(bool enabled) async {
    await _prefs.setBool(_emailNotificationsKey, enabled);
  }

  Future<bool> isSMSEnabled() async {
    return _prefs.getBool(_smsNotificationsKey) ?? true;
  }

  Future<void> setSMSEnabled(bool enabled) async {
    await _prefs.setBool(_smsNotificationsKey, enabled);
  }

  bool isQuietTime() {
    final now = TimeOfDay.now();
    final quietHours = _prefs.getString(_quietHoursKey);
    if (quietHours == null) return false;

    final hours = QuietHours.fromJson(
      Map<String, dynamic>.from(const JsonDecoder().convert(quietHours)),
    );
    if (!hours.enabled) return false;

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = hours.start.hour * 60 + hours.start.minute;
    final endMinutes = hours.end.hour * 60 + hours.end.minute;

    if (startMinutes > endMinutes) {
      // Quiet hours span midnight
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    } else {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }
  }

  Future<void> resetToDefaults() async {
    for (var notification in notifications) {
      await setPreference(notification.key, notification.defaultValue);
    }
    await setQuietHours(QuietHours.defaults());
    await setEmailEnabled(true);
    await setSMSEnabled(true);
  }
}
