import 'package:equatable/equatable.dart';
import '../../../../core/models/money.dart';

enum LoanStatus { active, pending, approved, rejected, closed }
enum LoanType { personal, business, education, emergency }

class Loan extends Equatable {
  final String id;
  final LoanType type;
  final LoanStatus status;
  final Money amount;
  final Money balance;
  final double interestRate;
  final DateTime startDate;
  final DateTime dueDate;
  final Money? monthlyRepayment;
  final String? purpose;
  final bool hasGuarantor;

  const Loan({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.balance,
    required this.interestRate,
    required this.startDate,
    required this.dueDate,
    this.monthlyRepayment,
    this.purpose,
    this.hasGuarantor = false,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    status,
    amount,
    balance,
    interestRate,
    startDate,
    dueDate,
    monthlyRepayment,
    purpose,
    hasGuarantor,
  ];

  Loan copyWith({
    String? id,
    LoanType? type,
    LoanStatus? status,
    Money? amount,
    Money? balance,
    double? interestRate,
    DateTime? startDate,
    DateTime? dueDate,
    Money? monthlyRepayment,
    String? purpose,
    bool? hasGuarantor,
  }) {
    return Loan(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      balance: balance ?? this.balance,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      monthlyRepayment: monthlyRepayment ?? this.monthlyRepayment,
      purpose: purpose ?? this.purpose,
      hasGuarantor: hasGuarantor ?? this.hasGuarantor,
    );
  }
}
