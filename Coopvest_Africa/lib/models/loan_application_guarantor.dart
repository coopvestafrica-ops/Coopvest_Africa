/// LoanApplicationGuarantor - represents a guarantor for a loan application (before the loan is created)
class LoanApplicationGuarantor {
  final String userId; // Guarantor's user ID
  final String? email;
  final String? phone;
  final String? name;
  
  /// Relationship type: 'friend', 'family', 'colleague', 'business_partner'
  final String relationship;
  
  /// Whether employment verification is required
  final bool employmentVerificationRequired;
  
  /// Verification status: 'pending', 'verified', 'rejected'
  final String verificationStatus;
  
  /// Confirmation status: 'pending', 'accepted', 'declined'
  final String confirmationStatus;

  LoanApplicationGuarantor({
    required this.userId,
    this.email,
    this.phone,
    this.name,
    required this.relationship,
    this.employmentVerificationRequired = false,
    this.verificationStatus = 'pending',
    this.confirmationStatus = 'pending',
  });

  /// Check if guarantor has confirmed
  bool get hasConfirmed => confirmationStatus == 'accepted';

  /// Check if guarantor is verified
  bool get isVerified => verificationStatus == 'verified';

  /// Factory constructor from JSON
  factory LoanApplicationGuarantor.fromJson(Map<String, dynamic> json) {
    return LoanApplicationGuarantor(
      userId: json['user_id'] ?? json['userId'] ?? '',
      email: json['email'],
      phone: json['phone'],
      name: json['name'],
      relationship: json['relationship'] ?? 'friend',
      employmentVerificationRequired: json['employment_verification_required'] ?? json['employmentVerificationRequired'] ?? false,
      verificationStatus: json['verification_status'] ?? json['verificationStatus'] ?? 'pending',
      confirmationStatus: json['confirmation_status'] ?? json['confirmationStatus'] ?? 'pending',
    );
  }

  /// Convert to JSON for sending to API
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'phone': phone,
      'name': name,
      'relationship': relationship,
      'employment_verification_required': employmentVerificationRequired,
      'verification_status': verificationStatus,
      'confirmation_status': confirmationStatus,
    };
  }

  /// Convert to request format for sending invitation
  Map<String, dynamic> toInvitationRequest() {
    return {
      'guarantor_email': email,
      'guarantor_phone': phone,
      'guarantor_name': name,
      'relationship': relationship,
      'employment_verification_required': employmentVerificationRequired,
    };
  }

  /// Create a copy with modifications
  LoanApplicationGuarantor copyWith({
    String? userId,
    String? email,
    String? phone,
    String? name,
    String? relationship,
    bool? employmentVerificationRequired,
    String? verificationStatus,
    String? confirmationStatus,
  }) {
    return LoanApplicationGuarantor(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      employmentVerificationRequired: employmentVerificationRequired ?? this.employmentVerificationRequired,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      confirmationStatus: confirmationStatus ?? this.confirmationStatus,
    );
  }

  @override
  String toString() => 'LoanApplicationGuarantor(userId: $userId, relationship: $relationship, status: $confirmationStatus)';
}
