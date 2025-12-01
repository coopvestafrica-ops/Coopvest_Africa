import 'package:equatable/equatable.dart';

class LoanProjection extends Equatable {
  final double amount;
  final double monthlyPayment;
  final double totalInterest;
  final double totalRepayment;
  final double interestRate;
  final int durationMonths;
  final DateTime startDate;
  final DateTime endDate;
  final List<ProjectedPayment> paymentSchedule;

  const LoanProjection({
    required this.amount,
    required this.monthlyPayment,
    required this.totalInterest,
    required this.totalRepayment,
    required this.interestRate,
    required this.durationMonths,
    required this.startDate,
    required this.endDate,
    required this.paymentSchedule,
  });

  factory LoanProjection.fromMap(Map<String, dynamic> map) {
    return LoanProjection(
      amount: map['amount'].toDouble(),
      monthlyPayment: map['monthlyPayment'].toDouble(),
      totalInterest: map['totalInterest'].toDouble(),
      totalRepayment: map['totalRepayment'].toDouble(),
      interestRate: map['interestRate'].toDouble(),
      durationMonths: map['durationMonths'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      paymentSchedule: (map['paymentSchedule'] as List)
          .map((item) => ProjectedPayment.fromMap(item))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'monthlyPayment': monthlyPayment,
      'totalInterest': totalInterest,
      'totalRepayment': totalRepayment,
      'interestRate': interestRate,
      'durationMonths': durationMonths,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'paymentSchedule': paymentSchedule.map((x) => x.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        amount,
        monthlyPayment,
        totalInterest,
        totalRepayment,
        interestRate,
        durationMonths,
        startDate,
        endDate,
        paymentSchedule,
      ];
}

class ProjectedPayment extends Equatable {
  final DateTime dueDate;
  final double principal;
  final double interest;
  final double totalPayment;
  final double remainingBalance;
  final int paymentNumber;

  const ProjectedPayment({
    required this.dueDate,
    required this.principal,
    required this.interest,
    required this.totalPayment,
    required this.remainingBalance,
    required this.paymentNumber,
  });

  factory ProjectedPayment.fromMap(Map<String, dynamic> map) {
    return ProjectedPayment(
      dueDate: DateTime.parse(map['dueDate']),
      principal: map['principal'].toDouble(),
      interest: map['interest'].toDouble(),
      totalPayment: map['totalPayment'].toDouble(),
      remainingBalance: map['remainingBalance'].toDouble(),
      paymentNumber: map['paymentNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dueDate': dueDate.toIso8601String(),
      'principal': principal,
      'interest': interest,
      'totalPayment': totalPayment,
      'remainingBalance': remainingBalance,
      'paymentNumber': paymentNumber,
    };
  }

  @override
  List<Object?> get props => [
        dueDate,
        principal,
        interest,
        totalPayment,
        remainingBalance,
        paymentNumber,
      ];
}
