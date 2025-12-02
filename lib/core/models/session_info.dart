import 'package:meta/meta.dart';

/// Represents information about a user's active session
@immutable
class SessionInfo {
  final String deviceId;
  final String platform;
  final String appVersion;
  final DateTime loginTime;
  final DateTime lastActivityTime;
  final String ipAddress;
  final bool isMfaEnabled;
  final bool isBiometricsEnabled;
  final Map<String, dynamic> deviceInfo;

  const SessionInfo({
    required this.deviceId,
    required this.platform,
    required this.appVersion,
    required this.loginTime,
    required this.lastActivityTime,
    required this.ipAddress,
    required this.isMfaEnabled,
    required this.isBiometricsEnabled,
    required this.deviceInfo,
  });

  /// Create a session info object from JSON data
  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      deviceId: json['deviceId'] as String,
      platform: json['platform'] as String,
      appVersion: json['appVersion'] as String,
      loginTime: DateTime.parse(json['loginTime'] as String),
      lastActivityTime: DateTime.parse(json['lastActivityTime'] as String),
      ipAddress: json['ipAddress'] as String,
      isMfaEnabled: json['isMfaEnabled'] as bool,
      isBiometricsEnabled: json['isBiometricsEnabled'] as bool,
      deviceInfo: json['deviceInfo'] as Map<String, dynamic>,
    );
  }

  /// Convert this object to JSON
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'platform': platform,
      'appVersion': appVersion,
      'loginTime': loginTime.toIso8601String(),
      'lastActivityTime': lastActivityTime.toIso8601String(),
      'ipAddress': ipAddress,
      'isMfaEnabled': isMfaEnabled,
      'isBiometricsEnabled': isBiometricsEnabled,
      'deviceInfo': deviceInfo,
    };
  }

  /// Create a copy of this object with some fields updated
  SessionInfo copyWith({
    String? deviceId,
    String? platform,
    String? appVersion,
    DateTime? loginTime,
    DateTime? lastActivityTime,
    String? ipAddress,
    bool? isMfaEnabled,
    bool? isBiometricsEnabled,
    Map<String, dynamic>? deviceInfo,
  }) {
    return SessionInfo(
      deviceId: deviceId ?? this.deviceId,
      platform: platform ?? this.platform,
      appVersion: appVersion ?? this.appVersion,
      loginTime: loginTime ?? this.loginTime,
      lastActivityTime: lastActivityTime ?? this.lastActivityTime,
      ipAddress: ipAddress ?? this.ipAddress,
      isMfaEnabled: isMfaEnabled ?? this.isMfaEnabled,
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionInfo &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          platform == other.platform &&
          appVersion == other.appVersion &&
          loginTime == other.loginTime &&
          lastActivityTime == other.lastActivityTime &&
          ipAddress == other.ipAddress &&
          isMfaEnabled == other.isMfaEnabled &&
          isBiometricsEnabled == other.isBiometricsEnabled;

  @override
  int get hashCode =>
      deviceId.hashCode ^
      platform.hashCode ^
      appVersion.hashCode ^
      loginTime.hashCode ^
      lastActivityTime.hashCode ^
      ipAddress.hashCode ^
      isMfaEnabled.hashCode ^
      isBiometricsEnabled.hashCode;

  @override
  String toString() =>
      'SessionInfo(deviceId: $deviceId, platform: $platform, '
      'appVersion: $appVersion, loginTime: $loginTime, '
      'lastActivityTime: $lastActivityTime)';
}
