/// Guarantor Model - represents a user who guarantees a loan
class Guarantor {
  final String id;
  final String loanId;
  final String guarantorUserId;
  final String? guarantorName;
  final String? guarantorEmail;
  final String? guarantorPhone;
  
  /// Relationship type: 'friend', 'family', 'colleague', 'business_partner'
  final String relationship;
  
  /// Verification status: 'pending', 'verified', 'rejected', 'expired'
  final String verificationStatus;
  
  /// Whether employment verification is required for this guarantor
  final bool employmentVerificationRequired;
  
  /// Whether employment verification has been completed
  final bool employmentVerificationCompleted;
  
  /// URL to uploaded employment verification document
  final String? employmentVerificationUrl;
  
  /// Confirmation status: 'pending', 'accepted', 'declined', 'revoked'
  final String confirmationStatus;
  
  /// Timestamp when invitation was sent
  final DateTime? invitationSentAt;
  
  /// Timestamp when invitation was accepted
  final DateTime? invitationAcceptedAt;
  
  /// Timestamp when invitation was declined
  final DateTime? invitationDeclinedAt;
  
  /// QR code as base64 string or URL
  final String qrCode;
  
  /// QR code token for verification
  final String qrCodeToken;
  
  /// When QR code expires
  final DateTime qrCodeExpiresAt;
  
  /// Optional notes from loan applicant or guarantor
  final String? notes;
  
  /// Liability amount for this guarantor (portion of loan they're liable for)
  final double? liabilityAmount;
  
  /// Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  Guarantor({
    required this.id,
    required this.loanId,
    required this.guarantorUserId,
    this.guarantorName,
    this.guarantorEmail,
    this.guarantorPhone,
    required this.relationship,
    this.verificationStatus = 'pending',
    this.employmentVerificationRequired = false,
    this.employmentVerificationCompleted = false,
    this.employmentVerificationUrl,
    this.confirmationStatus = 'pending',
    this.invitationSentAt,
    this.invitationAcceptedAt,
    this.invitationDeclinedAt,
    required this.qrCode,
    required this.qrCodeToken,
    required this.qrCodeExpiresAt,
    this.notes,
    this.liabilityAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if guarantor has accepted
  bool get hasAccepted => confirmationStatus == 'accepted';

  /// Check if guarantor is verified
  bool get isVerified => verificationStatus == 'verified';

  /// Check if QR code is still valid
  bool get isQrCodeValid => DateTime.now().isBefore(qrCodeExpiresAt);

  /// Get the liability percentage (useful for display)
  double get liabilityPercentage => liabilityAmount != null ? (liabilityAmount! * 100) : 0.0;

  /// Factory constructor from JSON
  factory Guarantor.fromJson(Map<String, dynamic> json) {
    return Guarantor(
      id: json['id'] ?? '',
      loanId: json['loan_id'] ?? json['loanId'] ?? '',
      guarantorUserId: json['guarantor_user_id'] ?? json['guarantorUserId'] ?? '',
      guarantorName: json['guarantor_name'] ?? json['guarantorName'],
      guarantorEmail: json['guarantor_email'] ?? json['guarantorEmail'],
      guarantorPhone: json['guarantor_phone'] ?? json['guarantorPhone'],
      relationship: json['relationship'] ?? 'friend',
      verificationStatus: json['verification_status'] ?? json['verificationStatus'] ?? 'pending',
      employmentVerificationRequired: json['employment_verification_required'] ?? json['employmentVerificationRequired'] ?? false,
      employmentVerificationCompleted: json['employment_verification_completed'] ?? json['employmentVerificationCompleted'] ?? false,
      employmentVerificationUrl: json['employment_verification_url'] ?? json['employmentVerificationUrl'],
      confirmationStatus: json['confirmation_status'] ?? json['confirmationStatus'] ?? 'pending',
      invitationSentAt: json['invitation_sent_at'] != null 
        ? DateTime.parse(json['invitation_sent_at'])
        : null,
      invitationAcceptedAt: json['invitation_accepted_at'] != null 
        ? DateTime.parse(json['invitation_accepted_at'])
        : null,
      invitationDeclinedAt: json['invitation_declined_at'] != null 
        ? DateTime.parse(json['invitation_declined_at'])
        : null,
      qrCode: json['qr_code'] ?? json['qrCode'] ?? '',
      qrCodeToken: json['qr_code_token'] ?? json['qrCodeToken'] ?? '',
      qrCodeExpiresAt: DateTime.parse(json['qr_code_expires_at'] ?? json['qrCodeExpiresAt'] ?? DateTime.now().add(Duration(days: 7)).toIso8601String()),
      notes: json['notes'],
      liabilityAmount: (json['liability_amount'] ?? json['liabilityAmount'])?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loan_id': loanId,
      'guarantor_user_id': guarantorUserId,
      'guarantor_name': guarantorName,
      'guarantor_email': guarantorEmail,
      'guarantor_phone': guarantorPhone,
      'relationship': relationship,
      'verification_status': verificationStatus,
      'employment_verification_required': employmentVerificationRequired,
      'employment_verification_completed': employmentVerificationCompleted,
      'employment_verification_url': employmentVerificationUrl,
      'confirmation_status': confirmationStatus,
      'invitation_sent_at': invitationSentAt?.toIso8601String(),
      'invitation_accepted_at': invitationAcceptedAt?.toIso8601String(),
      'invitation_declined_at': invitationDeclinedAt?.toIso8601String(),
      'qr_code': qrCode,
      'qr_code_token': qrCodeToken,
      'qr_code_expires_at': qrCodeExpiresAt.toIso8601String(),
      'notes': notes,
      'liability_amount': liabilityAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modifications
  Guarantor copyWith({
    String? id,
    String? loanId,
    String? guarantorUserId,
    String? guarantorName,
    String? guarantorEmail,
    String? guarantorPhone,
    String? relationship,
    String? verificationStatus,
    bool? employmentVerificationRequired,
    bool? employmentVerificationCompleted,
    String? employmentVerificationUrl,
    String? confirmationStatus,
    DateTime? invitationSentAt,
    DateTime? invitationAcceptedAt,
    DateTime? invitationDeclinedAt,
    String? qrCode,
    String? qrCodeToken,
    DateTime? qrCodeExpiresAt,
    String? notes,
    double? liabilityAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Guarantor(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      guarantorUserId: guarantorUserId ?? this.guarantorUserId,
      guarantorName: guarantorName ?? this.guarantorName,
      guarantorEmail: guarantorEmail ?? this.guarantorEmail,
      guarantorPhone: guarantorPhone ?? this.guarantorPhone,
      relationship: relationship ?? this.relationship,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      employmentVerificationRequired: employmentVerificationRequired ?? this.employmentVerificationRequired,
      employmentVerificationCompleted: employmentVerificationCompleted ?? this.employmentVerificationCompleted,
      employmentVerificationUrl: employmentVerificationUrl ?? this.employmentVerificationUrl,
      confirmationStatus: confirmationStatus ?? this.confirmationStatus,
      invitationSentAt: invitationSentAt ?? this.invitationSentAt,
      invitationAcceptedAt: invitationAcceptedAt ?? this.invitationAcceptedAt,
      invitationDeclinedAt: invitationDeclinedAt ?? this.invitationDeclinedAt,
      qrCode: qrCode ?? this.qrCode,
      qrCodeToken: qrCodeToken ?? this.qrCodeToken,
      qrCodeExpiresAt: qrCodeExpiresAt ?? this.qrCodeExpiresAt,
      notes: notes ?? this.notes,
      liabilityAmount: liabilityAmount ?? this.liabilityAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Guarantor(id: $id, loanId: $loanId, relationship: $relationship, status: $confirmationStatus)';
}
