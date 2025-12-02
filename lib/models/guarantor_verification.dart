/// VerificationDocument - represents a single verification document
class VerificationDocument {
  final String id;
  final String type; // 'employment_letter', 'payslip', 'bank_statement', 'id_card', etc.
  final String? fileName;
  final String? filePath;
  final String? fileUrl;
  final DateTime uploadedAt;

  VerificationDocument({
    required this.id,
    required this.type,
    this.fileName,
    this.filePath,
    this.fileUrl,
    required this.uploadedAt,
  });

  factory VerificationDocument.fromJson(Map<String, dynamic> json) {
    return VerificationDocument(
      id: json['id'] ?? '',
      type: json['type'] ?? 'employment_letter',
      fileName: json['file_name'] ?? json['fileName'],
      filePath: json['file_path'] ?? json['filePath'],
      fileUrl: json['file_url'] ?? json['fileUrl'],
      uploadedAt: DateTime.parse(json['uploaded_at'] ?? json['uploadedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'file_name': fileName,
      'file_path': filePath,
      'file_url': fileUrl,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}

/// GuarantorVerification Model - represents the verification status of a guarantor
class GuarantorVerification {
  final String id;
  final String guarantorId;
  final List<VerificationDocument> verificationDocuments;
  
  /// Status: 'pending', 'verified', 'rejected'
  final String verificationStatus;
  
  /// When verification was submitted
  final DateTime submittedAt;
  
  /// When verification was reviewed
  final DateTime? reviewedAt;
  
  /// Reason for rejection (if rejected)
  final String? rejectionReason;
  
  /// Employment verification completed
  final bool employmentVerified;
  
  /// Employment verification URL/document
  final String? employmentVerificationUrl;
  
  /// Notes from verifier
  final String? verifierNotes;

  GuarantorVerification({
    required this.id,
    required this.guarantorId,
    required this.verificationDocuments,
    this.verificationStatus = 'pending',
    required this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.employmentVerified = false,
    this.employmentVerificationUrl,
    this.verifierNotes,
  });

  /// Check if verification is complete
  bool get isComplete => verificationStatus != 'pending';

  /// Check if verification is approved
  bool get isApproved => verificationStatus == 'verified';

  /// Check if verification is rejected
  bool get isRejected => verificationStatus == 'rejected';

  /// Get the age of the verification request
  Duration get age => DateTime.now().difference(submittedAt);

  /// Get human-readable status
  String get statusLabel {
    switch (verificationStatus) {
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      case 'pending':
      default:
        return 'Pending Review';
    }
  }

  /// Factory constructor from JSON
  factory GuarantorVerification.fromJson(Map<String, dynamic> json) {
    final docs = (json['verification_documents'] ?? json['verificationDocuments'] ?? []) as List;
    
    return GuarantorVerification(
      id: json['id'] ?? '',
      guarantorId: json['guarantor_id'] ?? json['guarantorId'] ?? '',
      verificationDocuments: docs
          .map((doc) => VerificationDocument.fromJson(doc))
          .toList(),
      verificationStatus: json['verification_status'] ?? json['verificationStatus'] ?? 'pending',
      submittedAt: DateTime.parse(json['submitted_at'] ?? json['submittedAt'] ?? DateTime.now().toIso8601String()),
      reviewedAt: json['reviewed_at'] != null 
        ? DateTime.parse(json['reviewed_at'])
        : json['reviewedAt'] != null
        ? DateTime.parse(json['reviewedAt'])
        : null,
      rejectionReason: json['rejection_reason'] ?? json['rejectionReason'],
      employmentVerified: json['employment_verified'] ?? json['employmentVerified'] ?? false,
      employmentVerificationUrl: json['employment_verification_url'] ?? json['employmentVerificationUrl'],
      verifierNotes: json['verifier_notes'] ?? json['verifierNotes'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guarantor_id': guarantorId,
      'verification_documents': verificationDocuments.map((doc) => doc.toJson()).toList(),
      'verification_status': verificationStatus,
      'submitted_at': submittedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'employment_verified': employmentVerified,
      'employment_verification_url': employmentVerificationUrl,
      'verifier_notes': verifierNotes,
    };
  }

  /// Create a copy with modifications
  GuarantorVerification copyWith({
    String? id,
    String? guarantorId,
    List<VerificationDocument>? verificationDocuments,
    String? verificationStatus,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? rejectionReason,
    bool? employmentVerified,
    String? employmentVerificationUrl,
    String? verifierNotes,
  }) {
    return GuarantorVerification(
      id: id ?? this.id,
      guarantorId: guarantorId ?? this.guarantorId,
      verificationDocuments: verificationDocuments ?? this.verificationDocuments,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      employmentVerified: employmentVerified ?? this.employmentVerified,
      employmentVerificationUrl: employmentVerificationUrl ?? this.employmentVerificationUrl,
      verifierNotes: verifierNotes ?? this.verifierNotes,
    );
  }

  @override
  String toString() => 'GuarantorVerification(id: $id, status: $verificationStatus, docsCount: ${verificationDocuments.length})';
}
