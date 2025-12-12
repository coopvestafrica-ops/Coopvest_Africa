/// GuarantorInvitation Model - represents an invitation sent to a potential guarantor
class GuarantorInvitation {
  final String id;
  final String loanId;
  final String guarantorEmail;
  final String? guarantorPhone;
  final String? guarantorName;
  
  /// Unique token for accepting/declining invitation
  final String invitationToken;
  
  /// Full invitation link (can be sent via QR code or email)
  final String invitationLink;
  
  /// Status: 'pending', 'accepted', 'declined', 'expired'
  final String status;
  
  /// When invitation was sent
  final DateTime sentAt;
  
  /// When invitation was accepted
  final DateTime? acceptedAt;
  
  /// When invitation expires
  final DateTime expiresAt;
  
  /// Relationship type requested
  final String? relationship;
  
  /// Loan amount for context
  final double? loanAmount;
  
  /// Loan duration in months
  final int? loanDurationMonths;

  GuarantorInvitation({
    required this.id,
    required this.loanId,
    required this.guarantorEmail,
    this.guarantorPhone,
    this.guarantorName,
    required this.invitationToken,
    required this.invitationLink,
    this.status = 'pending',
    required this.sentAt,
    this.acceptedAt,
    required this.expiresAt,
    this.relationship,
    this.loanAmount,
    this.loanDurationMonths,
  });

  /// Check if invitation is still valid
  bool get isValid => DateTime.now().isBefore(expiresAt) && status == 'pending';

  /// Check if invitation has expired
  bool get hasExpired => DateTime.now().isAfter(expiresAt) || status == 'expired';

  /// Get time remaining until expiration
  Duration? get timeRemaining {
    final now = DateTime.now();
    if (now.isBefore(expiresAt)) {
      return expiresAt.difference(now);
    }
    return null;
  }

  /// Get hours remaining
  int? get hoursRemaining {
    final remaining = timeRemaining;
    if (remaining != null) {
      return remaining.inHours;
    }
    return null;
  }

  /// Factory constructor from JSON
  factory GuarantorInvitation.fromJson(Map<String, dynamic> json) {
    return GuarantorInvitation(
      id: json['id'] ?? '',
      loanId: json['loan_id'] ?? json['loanId'] ?? '',
      guarantorEmail: json['guarantor_email'] ?? json['guarantorEmail'] ?? '',
      guarantorPhone: json['guarantor_phone'] ?? json['guarantorPhone'],
      guarantorName: json['guarantor_name'] ?? json['guarantorName'],
      invitationToken: json['invitation_token'] ?? json['invitationToken'] ?? '',
      invitationLink: json['invitation_link'] ?? json['invitationLink'] ?? '',
      status: json['status'] ?? 'pending',
      sentAt: DateTime.parse(json['sent_at'] ?? json['sentAt'] ?? DateTime.now().toIso8601String()),
      acceptedAt: json['accepted_at'] != null 
        ? DateTime.parse(json['accepted_at'])
        : json['acceptedAt'] != null
        ? DateTime.parse(json['acceptedAt'])
        : null,
      expiresAt: DateTime.parse(json['expires_at'] ?? json['expiresAt'] ?? DateTime.now().add(Duration(days: 7)).toIso8601String()),
      relationship: json['relationship'],
      loanAmount: (json['loan_amount'] ?? json['loanAmount'])?.toDouble(),
      loanDurationMonths: json['loan_duration_months'] ?? json['loanDurationMonths'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loan_id': loanId,
      'guarantor_email': guarantorEmail,
      'guarantor_phone': guarantorPhone,
      'guarantor_name': guarantorName,
      'invitation_token': invitationToken,
      'invitation_link': invitationLink,
      'status': status,
      'sent_at': sentAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'relationship': relationship,
      'loan_amount': loanAmount,
      'loan_duration_months': loanDurationMonths,
    };
  }

  /// Create a copy with modifications
  GuarantorInvitation copyWith({
    String? id,
    String? loanId,
    String? guarantorEmail,
    String? guarantorPhone,
    String? guarantorName,
    String? invitationToken,
    String? invitationLink,
    String? status,
    DateTime? sentAt,
    DateTime? acceptedAt,
    DateTime? expiresAt,
    String? relationship,
    double? loanAmount,
    int? loanDurationMonths,
  }) {
    return GuarantorInvitation(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      guarantorEmail: guarantorEmail ?? this.guarantorEmail,
      guarantorPhone: guarantorPhone ?? this.guarantorPhone,
      guarantorName: guarantorName ?? this.guarantorName,
      invitationToken: invitationToken ?? this.invitationToken,
      invitationLink: invitationLink ?? this.invitationLink,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      relationship: relationship ?? this.relationship,
      loanAmount: loanAmount ?? this.loanAmount,
      loanDurationMonths: loanDurationMonths ?? this.loanDurationMonths,
    );
  }

  @override
  String toString() => 'GuarantorInvitation(id: $id, email: $guarantorEmail, status: $status)';
}
