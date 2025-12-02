class Loan {
  final String id;
  final String userId;
  final String productId;
  final String applicationId;
  final double amount;
  final double interestRate;
  final String interestType;
  final int duration;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final double totalRepaymentAmount;
  final double totalInterestAmount;
  final double amountPaid;
  final double amountRemaining;
  final DateTime nextRepaymentDate;
  final double nextRepaymentAmount;
  final Map<String, dynamic>? metadata;

  Loan({
    required this.id,
    required this.userId,
    required this.productId,
    required this.applicationId,
    required this.amount,
    required this.interestRate,
    required this.interestType,
    required this.duration,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.totalRepaymentAmount,
    required this.totalInterestAmount,
    required this.amountPaid,
    required this.amountRemaining,
    required this.nextRepaymentDate,
    required this.nextRepaymentAmount,
    this.metadata,
  });

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] as String,
      userId: map['userId'] as String,
      productId: map['productId'] as String,
      applicationId: map['applicationId'] as String,
      amount: (map['amount'] as num).toDouble(),
      interestRate: (map['interestRate'] as num).toDouble(),
      interestType: map['interestType'] as String,
      duration: map['duration'] as int,
      status: map['status'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      totalRepaymentAmount: (map['totalRepaymentAmount'] as num).toDouble(),
      totalInterestAmount: (map['totalInterestAmount'] as num).toDouble(),
      amountPaid: (map['amountPaid'] as num).toDouble(),
      amountRemaining: (map['amountRemaining'] as num).toDouble(),
      nextRepaymentDate: DateTime.parse(map['nextRepaymentDate'] as String),
      nextRepaymentAmount: (map['nextRepaymentAmount'] as num).toDouble(),
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
      'applicationId': applicationId,
      'amount': amount,
      'interestRate': interestRate,
      'interestType': interestType,
      'duration': duration,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalRepaymentAmount': totalRepaymentAmount,
      'totalInterestAmount': totalInterestAmount,
      'amountPaid': amountPaid,
      'amountRemaining': amountRemaining,
      'nextRepaymentDate': nextRepaymentDate.toIso8601String(),
      'nextRepaymentAmount': nextRepaymentAmount,
      'metadata': metadata,
    }..removeWhere((key, value) => value == null);
  }
}
