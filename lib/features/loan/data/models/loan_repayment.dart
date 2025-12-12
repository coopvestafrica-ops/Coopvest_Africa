class LoanRepayment {
  final String id;
  final String loanId;
  final double amount;
  final double principalAmount;
  final double interestAmount;
  final DateTime dueDate;
  final String status;
  final DateTime? paidAt;
  final String? paymentMethod;
  final String? referenceCode;
  final Map<String, dynamic>? metadata;

  LoanRepayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.principalAmount,
    required this.interestAmount,
    required this.dueDate,
    required this.status,
    this.paidAt,
    this.paymentMethod,
    this.referenceCode,
    this.metadata,
  });

  factory LoanRepayment.fromMap(Map<String, dynamic> map) {
    return LoanRepayment(
      id: map['id'] as String,
      loanId: map['loanId'] as String,
      amount: (map['amount'] as num).toDouble(),
      principalAmount: (map['principalAmount'] as num).toDouble(),
      interestAmount: (map['interestAmount'] as num).toDouble(),
      dueDate: DateTime.parse(map['dueDate'] as String),
      status: map['status'] as String,
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt'] as String) : null,
      paymentMethod: map['paymentMethod'] as String?,
      referenceCode: map['referenceCode'] as String?,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loanId': loanId,
      'amount': amount,
      'principalAmount': principalAmount,
      'interestAmount': interestAmount,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'paidAt': paidAt?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'referenceCode': referenceCode,
      'metadata': metadata,
    }..removeWhere((key, value) => value == null);
  }
}
