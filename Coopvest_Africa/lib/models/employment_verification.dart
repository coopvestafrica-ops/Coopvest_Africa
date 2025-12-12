class EmploymentVerification {
  final String userId;
  final String companyName;
  final String? employeeId;
  final String position;
  final String? companyEmail;
  final bool isEmailVerified;
  final DateTime employmentStartDate;
  final double monthlySalary;
  final String employmentStatus; // permanent, contract
  final List<String> documentUrls; // employment letter, company ID card
  final String verificationStatus; // pending, verified, rejected
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final Map<String, bool> verificationSteps;

  EmploymentVerification({
    required this.userId,
    required this.companyName,
    this.employeeId,
    required this.position,
    this.companyEmail,
    this.isEmailVerified = false,
    required this.employmentStartDate,
    required this.monthlySalary,
    required this.employmentStatus,
    required this.documentUrls,
    this.verificationStatus = 'pending',
    this.verifiedAt,
    this.rejectionReason,
    required this.verificationSteps,
  });

  factory EmploymentVerification.fromJson(Map<String, dynamic> json) {
    return EmploymentVerification(
      userId: json['userId'],
      companyName: json['companyName'],
      employeeId: json['employeeId'],
      position: json['position'],
      companyEmail: json['companyEmail'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      employmentStartDate: DateTime.parse(json['employmentStartDate']),
      monthlySalary: json['monthlySalary'].toDouble(),
      employmentStatus: json['employmentStatus'],
      documentUrls: List<String>.from(json['documentUrls']),
      verificationStatus: json['verificationStatus'],
      verifiedAt: json['verifiedAt'] != null ? DateTime.parse(json['verifiedAt']) : null,
      rejectionReason: json['rejectionReason'],
      verificationSteps: Map<String, bool>.from(json['verificationSteps']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'companyName': companyName,
      'employeeId': employeeId,
      'position': position,
      'companyEmail': companyEmail,
      'isEmailVerified': isEmailVerified,
      'employmentStartDate': employmentStartDate.toIso8601String(),
      'monthlySalary': monthlySalary,
      'employmentStatus': employmentStatus,
      'documentUrls': documentUrls,
      'verificationStatus': verificationStatus,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'verificationSteps': verificationSteps,
    };
  }

  EmploymentVerification copyWith({
    String? userId,
    String? companyName,
    String? employeeId,
    String? position,
    String? companyEmail,
    bool? isEmailVerified,
    DateTime? employmentStartDate,
    double? monthlySalary,
    String? employmentStatus,
    List<String>? documentUrls,
    String? verificationStatus,
    DateTime? verifiedAt,
    String? rejectionReason,
    Map<String, bool>? verificationSteps,
  }) {
    return EmploymentVerification(
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      employeeId: employeeId ?? this.employeeId,
      position: position ?? this.position,
      companyEmail: companyEmail ?? this.companyEmail,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      employmentStartDate: employmentStartDate ?? this.employmentStartDate,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      documentUrls: documentUrls ?? this.documentUrls,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verificationSteps: verificationSteps ?? this.verificationSteps,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is EmploymentVerification &&
      other.userId == userId &&
      other.companyName == companyName &&
      other.employeeId == employeeId &&
      other.position == position &&
      other.companyEmail == companyEmail &&
      other.isEmailVerified == isEmailVerified &&
      other.employmentStartDate == employmentStartDate &&
      other.monthlySalary == monthlySalary &&
      other.employmentStatus == employmentStatus &&
      other.verificationStatus == verificationStatus &&
      other.verifiedAt == verifiedAt &&
      other.rejectionReason == rejectionReason &&
      other.verificationSteps.toString() == verificationSteps.toString() &&
      other.documentUrls.toString() == documentUrls.toString();
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      companyName,
      employeeId,
      position,
      companyEmail,
      isEmailVerified,
      employmentStartDate,
      monthlySalary,
      employmentStatus,
      verificationStatus,
      verifiedAt,
      rejectionReason,
      Object.hashAll(verificationSteps.entries),
      Object.hashAll(documentUrls),
    );
  }
}
