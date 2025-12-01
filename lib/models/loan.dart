class Loan {
  final String id;
  final String userId;
  final double amount;
  final String status;
  final int tenureMonths;
  final DateTime startDate;
  final DateTime endDate;
  final double amountPaid;
  final bool isRollover;
  final double? remainingFromPrevious;
  final String? previousLoanId;
  final DateTime createdAt;
  final DateTime lastUpdated;

  Loan({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    required this.tenureMonths,
    required this.startDate,
    required this.endDate,
    required this.amountPaid,
    required this.isRollover,
    this.remainingFromPrevious,
    this.previousLoanId,
    required this.createdAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'status': status,
      'tenureMonths': tenureMonths,
      'startDate': startDate,
      'endDate': endDate,
      'amountPaid': amountPaid,
      'isRollover': isRollover,
      'remainingFromPrevious': remainingFromPrevious,
      'previousLoanId': previousLoanId,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] as String,
      userId: map['userId'] as String,
      amount: (map['amount'] as num).toDouble(),
      status: map['status'] as String,
      tenureMonths: (map['tenureMonths'] as num).toInt(),
      startDate: map['startDate'] as DateTime,
      endDate: map['endDate'] as DateTime,
      amountPaid: (map['amountPaid'] as num).toDouble(),
      isRollover: map['isRollover'] as bool,
      remainingFromPrevious: (map['remainingFromPrevious'] as num?)?.toDouble(),
      previousLoanId: map['previousLoanId'] as String?,
      createdAt: map['createdAt'] as DateTime,
      lastUpdated: map['lastUpdated'] as DateTime,
    );
  }
}
