import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// User model for backend synchronization
@JsonSerializable()
class UserModel {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'first_name')
  final String? firstName;

  @JsonKey(name: 'last_name')
  final String? lastName;

  @JsonKey(name: 'phone_number')
  final String? phoneNumber;

  @JsonKey(name: 'profile_picture_url')
  final String? profilePictureUrl;

  @JsonKey(name: 'bio')
  final String? bio;

  @JsonKey(name: 'is_verified')
  final bool isVerified;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @JsonKey(name: 'last_login')
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profilePictureUrl,
    this.bio,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
  });

  /// Get full name
  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    return '$first $last'.trim();
  }

  /// Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Copy with method
  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profilePictureUrl,
    String? bio,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName, isVerified: $isVerified)';
  }
}

/// Authentication response model
@JsonSerializable()
class AuthResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;

  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  @JsonKey(name: 'token_type')
  final String tokenType;

  @JsonKey(name: 'expires_in')
  final int expiresIn;

  @JsonKey(name: 'user')
  final UserModel user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  /// Get token expiry time
  DateTime get tokenExpiry {
    return DateTime.now().add(Duration(seconds: expiresIn));
  }

  /// Create from JSON
  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

/// Login request model
@JsonSerializable()
class LoginRequest {
  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'password')
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  /// Create from JSON
  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

/// Sign up request model
@JsonSerializable()
class SignUpRequest {
  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'password')
  final String password;

  @JsonKey(name: 'first_name')
  final String firstName;

  @JsonKey(name: 'last_name')
  final String lastName;

  @JsonKey(name: 'phone_number')
  final String? phoneNumber;

  SignUpRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
  });

  /// Create from JSON
  factory SignUpRequest.fromJson(Map<String, dynamic> json) =>
      _$SignUpRequestFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$SignUpRequestToJson(this);
}

/// Token refresh request model
@JsonSerializable()
class TokenRefreshRequest {
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  TokenRefreshRequest({required this.refreshToken});

  /// Create from JSON
  factory TokenRefreshRequest.fromJson(Map<String, dynamic> json) =>
      _$TokenRefreshRequestFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$TokenRefreshRequestToJson(this);
}
