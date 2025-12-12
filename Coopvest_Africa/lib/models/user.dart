class User {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isEmailVerified;

  // Personal Information
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final String? bvn;

  // Employment Information
  final String? employerName;
  final String? selectedEmployer; // The selected company from dropdown
  final String? employmentStatus; // Permanent, Contract, or Temporary
  final String? jobTitle;
  final String? workAddress;
  final double? monthlyIncome;
  final String? employmentStartDate;

  User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.photoUrl,
    required this.createdAt,
    this.isEmailVerified = false,
    // Personal Information
    this.dateOfBirth,
    this.gender,
    this.address,
    this.bvn,
    // Employment Information
    this.employerName,
    this.selectedEmployer,
    this.employmentStatus,
    this.jobTitle,
    this.workAddress,
    this.monthlyIncome,
    this.employmentStartDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      // Personal Information
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'address': address,
      'bvn': bvn,
      // Employment Information
      'employerName': employerName,
      'selectedEmployer': selectedEmployer,
      'employmentStatus': employmentStatus,
      'jobTitle': jobTitle,
      'workAddress': workAddress,
      'monthlyIncome': monthlyIncome,
      'employmentStartDate': employmentStartDate,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      photoUrl: json['photoUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      isEmailVerified: json['isEmailVerified'] ?? false,
      // Personal Information
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      address: json['address'],
      bvn: json['bvn'],
      // Employment Information
      employerName: json['employerName'],
      selectedEmployer: json['selectedEmployer'],
      employmentStatus: json['employmentStatus'],
      jobTitle: json['jobTitle'],
      workAddress: json['workAddress'],
      monthlyIncome: json['monthlyIncome']?.toDouble(),
      employmentStartDate: json['employmentStartDate'],
    );
  }
}
