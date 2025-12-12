class LoanApplication {
  final String id;
  final String userId;
  final String productId;
  final double amount;
  final int duration;
  final String purpose;
  final List<String> guarantorIds;
  final Map<String, dynamic> employmentDetails;
  final Map<String, dynamic> bankDetails;
  final List<String>? documentIds;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final Map<String, dynamic>? metadata;

  LoanApplication({
    required this.id,
    required this.userId,
    required this.productId,
    required this.amount,
    required this.duration,
    required this.purpose,
    required this.guarantorIds,
    required this.employmentDetails,
    required this.bankDetails,
    this.documentIds,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.approvedAt,
    this.rejectedAt,
    this.metadata,
  });

  factory LoanApplication.fromMap(Map<String, dynamic> map) {
    return LoanApplication(
      id: map['id'] as String,
      userId: map['userId'] as String,
      productId: map['productId'] as String,
      amount: (map['amount'] as num).toDouble(),
      duration: map['duration'] as int,
      purpose: map['purpose'] as String,
      guarantorIds: List<String>.from(map['guarantorIds'] as List),
      employmentDetails: Map<String, dynamic>.from(map['employmentDetails'] as Map),
      bankDetails: Map<String, dynamic>.from(map['bankDetails'] as Map),
      documentIds: map['documentIds'] != null
          ? List<String>.from(map['documentIds'] as List)
          : null,
      status: map['status'] as String,
      rejectionReason: map['rejectionReason'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      approvedAt: map['approvedAt'] != null
          ? DateTime.parse(map['approvedAt'] as String)
          : null,
      rejectedAt: map['rejectedAt'] != null
          ? DateTime.parse(map['rejectedAt'] as String)
          : null,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'amount': amount,
      'duration': duration,
      'purpose': purpose,
      'guarantorIds': guarantorIds,
      'employmentDetails': employmentDetails,
      'bankDetails': bankDetails,
      'documentIds': documentIds,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'metadata': metadata,
    }..removeWhere((key, value) => value == null);
  }
}
