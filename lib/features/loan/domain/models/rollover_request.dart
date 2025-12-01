enum RolloverRequestStatus {
  pending,
  approved,
  rejected,
  cancelled,
}

class RolloverRequest {
  final String id;
  final String oldLoanId;
  final String userId;
  final double newLoanAmount;
  final int newTenureMonths;
  final String status;
  final DateTime createdAt;
  final List<String> approvedGuarantors;
  final Map<String, dynamic>? metadata;

  const RolloverRequest({
    required this.id,
    required this.oldLoanId,
    required this.userId,
    required this.newLoanAmount,
    required this.newTenureMonths,
    required this.status,
    required this.createdAt,
    required this.approvedGuarantors,
    this.metadata,
  });

  RolloverRequest copyWith({
    String? id,
    String? oldLoanId,
    String? userId,
    double? newLoanAmount,
    int? newTenureMonths,
    String? status,
    DateTime? createdAt,
    List<String>? approvedGuarantors,
    Map<String, dynamic>? metadata,
  }) {
    return RolloverRequest(
      id: id ?? this.id,
      oldLoanId: oldLoanId ?? this.oldLoanId,
      userId: userId ?? this.userId,
      newLoanAmount: newLoanAmount ?? this.newLoanAmount,
      newTenureMonths: newTenureMonths ?? this.newTenureMonths,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedGuarantors: approvedGuarantors ?? this.approvedGuarantors,
      metadata: metadata ?? this.metadata,
    );
  }

  factory RolloverRequest.fromMap(Map<String, dynamic> map) {
    return RolloverRequest(
      id: map['id'] as String,
      oldLoanId: map['oldLoanId'] as String,
      userId: map['userId'] as String,
      newLoanAmount: (map['newLoanAmount'] as num).toDouble(),
      newTenureMonths: (map['newTenureMonths'] as num).toInt(),
      status: map['status'] as String,
      createdAt: map['createdAt'] as DateTime,
      approvedGuarantors: List<String>.from(map['approvedGuarantors'] as List),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'oldLoanId': oldLoanId,
      'userId': userId,
      'newLoanAmount': newLoanAmount,
      'newTenureMonths': newTenureMonths,
      'status': status,
      'createdAt': createdAt,
      'approvedGuarantors': approvedGuarantors,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'RolloverRequest(id: $id, oldLoanId: $oldLoanId, userId: $userId, '
      'newLoanAmount: $newLoanAmount, newTenureMonths: $newTenureMonths, '
      'status: $status, createdAt: $createdAt, '
      'approvedGuarantors: $approvedGuarantors, metadata: $metadata)';
  }
}
