class UserModel {
  final String id;
  final String email;

  // Personal Information
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String address;
  final String phone;
  final String bvn;
  final String? profilePhotoUrl;
  final String? governmentIdUrl;

  // Employment Information
  final String employerName;
  final String employmentStatus;
  final String jobTitle;
  final String workAddress;
  final double monthlyIncome;
  final DateTime employmentStartDate;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
    required this.phone,
    required this.bvn,
    this.profilePhotoUrl,
    this.governmentIdUrl,
    required this.employerName,
    required this.employmentStatus,
    required this.jobTitle,
    required this.workAddress,
    required this.monthlyIncome,
    required this.employmentStartDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'address': address,
      'phone': phone,
      'bvn': bvn,
      'profilePhotoUrl': profilePhotoUrl,
      'governmentIdUrl': governmentIdUrl,
      'employerName': employerName,
      'employmentStatus': employmentStatus,
      'jobTitle': jobTitle,
      'workAddress': workAddress,
      'monthlyIncome': monthlyIncome,
      'employmentStartDate': employmentStartDate.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      gender: json['gender'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      bvn: json['bvn'] as String,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      governmentIdUrl: json['governmentIdUrl'] as String?,
      employerName: json['employerName'] as String,
      employmentStatus: json['employmentStatus'] as String,
      jobTitle: json['jobTitle'] as String,
      workAddress: json['workAddress'] as String,
      monthlyIncome: json['monthlyIncome'] as double,
      employmentStartDate:
          DateTime.parse(json['employmentStartDate'] as String),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? phone,
    String? bvn,
    String? profilePhotoUrl,
    String? governmentIdUrl,
    String? employerName,
    String? employmentStatus,
    String? jobTitle,
    String? workAddress,
    double? monthlyIncome,
    DateTime? employmentStartDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      bvn: bvn ?? this.bvn,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      governmentIdUrl: governmentIdUrl ?? this.governmentIdUrl,
      employerName: employerName ?? this.employerName,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      jobTitle: jobTitle ?? this.jobTitle,
      workAddress: workAddress ?? this.workAddress,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      employmentStartDate: employmentStartDate ?? this.employmentStartDate,
    );
  }
}
