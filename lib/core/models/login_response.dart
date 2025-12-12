import 'user_role.dart';

class LoginResponse {
  final String id;
  final String firstName;
  final String email;
  final String token;
  final String refreshToken;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final UserRole role;
  final bool requiresMfa;
  final String? mfaPendingId;

  LoginResponse({
    required this.id,
    required this.firstName,
    required this.email,
    required this.token,
    required this.refreshToken,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.role,
    this.requiresMfa = false,
    this.mfaPendingId,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      id: json['id'].toString(),
      firstName: json['firstName'].toString(),
      email: json['email'].toString(),
      token: json['accessToken'].toString(),
      refreshToken: json['refreshToken'].toString(),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      role: UserRole.values.firstWhere(
        (role) => role.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.member,
      ),
      requiresMfa: json['requiresMfa'] as bool? ?? false,
      mfaPendingId: json['mfaPendingId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'email': email,
      'accessToken': token,
      'refreshToken': refreshToken,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'role': role.toString().split('.').last,
      'requiresMfa': requiresMfa,
      'mfaPendingId': mfaPendingId,
    };
  }

  LoginResponse copyWith({
    String? id,
    String? firstName,
    String? email,
    String? token,
    String? refreshToken,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    UserRole? role,
    bool? requiresMfa,
    String? mfaPendingId,
  }) {
    return LoginResponse(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      email: email ?? this.email,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      role: role ?? this.role,
      requiresMfa: requiresMfa ?? this.requiresMfa,
      mfaPendingId: mfaPendingId ?? this.mfaPendingId,
    );
  }
}
