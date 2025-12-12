import 'package:equatable/equatable.dart';

enum LoanStatus {
  pending,
  approved,
  rejected,
  cancelled,
  completed;

  String get displayName {
    switch (this) {
      case LoanStatus.pending:
        return 'Pending';
      case LoanStatus.approved:
        return 'Approved';
      case LoanStatus.rejected:
        return 'Rejected';
      case LoanStatus.cancelled:
        return 'Cancelled';
      case LoanStatus.completed:
        return 'Completed';
    }
  }
}

class LoanStatusDetails extends Equatable {
  final String loanId;
  final double amount;
  final double amountPaid;
  final DateTime applicationDate;
  final String purpose;
  final int durationMonths;
  final LoanStatus status;
  final DateTime? nextPaymentDate;
  final DateTime? lastPaymentDate;
  final String? rejectionReason;

  const LoanStatusDetails({
    required this.loanId,
    required this.amount,
    required this.amountPaid,
    required this.applicationDate,
    required this.purpose,
    required this.durationMonths,
    required this.status,
    this.nextPaymentDate,
    this.lastPaymentDate,
    this.rejectionReason,
  });

  factory LoanStatusDetails.fromJson(Map<String, dynamic> json) {
    return LoanStatusDetails(
      loanId: json['loan_id'],
      amount: (json['amount'] as num).toDouble(),
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
      applicationDate: DateTime.parse(json['application_date']),
      purpose: json['purpose'],
      durationMonths: json['duration'],
      status: LoanStatus.values.firstWhere(
        (e) => e.name == json['status'].toString().toLowerCase(),
        orElse: () => LoanStatus.pending,
      ),
      nextPaymentDate: json['next_payment_date'] != null
          ? DateTime.parse(json['next_payment_date'])
          : null,
      lastPaymentDate: json['last_payment_date'] != null
          ? DateTime.parse(json['last_payment_date'])
          : null,
      rejectionReason: json['rejection_reason'],
    );
  }

  @override
  List<Object?> get props => [
        loanId,
        amount,
        amountPaid,
        applicationDate,
        purpose,
        durationMonths,
        status,
        nextPaymentDate,
        lastPaymentDate,
        rejectionReason,
      ];
}
