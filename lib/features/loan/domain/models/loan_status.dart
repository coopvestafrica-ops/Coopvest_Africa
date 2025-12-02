import 'loan_service_interface.dart';

class LoanStatus {
  final String loanId;
  final String status;
  final double totalAmount;
  final double amountPaid;
  final double remainingAmount;
  final String? nextPaymentDate;
  final String? lastPaymentDate;
  final int completionPercentage;
  final String? rejectionReason;
  final Map<String, dynamic>? additionalInfo;

  LoanStatus({
    required this.loanId,
    required this.status,
    required this.totalAmount,
    required this.amountPaid,
    required this.remainingAmount,
    this.nextPaymentDate,
    this.lastPaymentDate,
    required this.completionPercentage,
    this.rejectionReason,
    this.additionalInfo,
  }) {
    // Validate status
    if (!LoanServiceInterface.validLoanStatuses.containsKey(status.toLowerCase())) {
      throw ArgumentError.value(
        status,
        'status',
        'Invalid loan status. Valid statuses are: ${LoanServiceInterface.validLoanStatuses.keys.join(", ")}'
      );
    }
  }

  factory LoanStatus.fromJson(Map<String, dynamic> json) {
    return LoanStatus(
      loanId: json['loan_id'] ?? json['loanId'],
      status: json['status'],
      totalAmount: json['total_amount']?.toDouble() ?? json['totalAmount']?.toDouble() ?? 0.0,
      amountPaid: json['amount_paid']?.toDouble() ?? json['amountPaid']?.toDouble() ?? 0.0,
      remainingAmount: json['remaining_amount']?.toDouble() ?? json['remainingAmount']?.toDouble() ?? 0.0,
      nextPaymentDate: json['next_payment_date'] ?? json['nextPaymentDate'],
      lastPaymentDate: json['last_payment_date'] ?? json['lastPaymentDate'],
      completionPercentage: json['completion_percentage'] ?? json['completionPercentage'] ?? 0,
      rejectionReason: json['rejection_reason'] ?? json['rejectionReason'],
      additionalInfo: json['additional_info'] ?? json['additionalInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loan_id': loanId,
      'status': status,
      'total_amount': totalAmount,
      'amount_paid': amountPaid,
      'remaining_amount': remainingAmount,
      'next_payment_date': nextPaymentDate,
      'last_payment_date': lastPaymentDate,
      'completion_percentage': completionPercentage,
      'rejection_reason': rejectionReason,
      'additional_info': additionalInfo,
    }..removeWhere((_, v) => v == null);
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isActive => status.toLowerCase() == 'active';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isDefaulted => status.toLowerCase() == 'defaulted';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isRolledOver => status.toLowerCase() == 'rolled_over';

  bool get needsGuarantors {
    // Check if loan is in a state where guarantors can be added
    if (!isPending && !isActive) return false;
    
    final currentGuarantorCount = additionalInfo?['guarantors_count'] ?? 0;
    return currentGuarantorCount < LoanServiceInterface.maxActiveGuarantees;
  }
}
