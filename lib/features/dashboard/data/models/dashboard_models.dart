import 'package:equatable/equatable.dart';
import '../../../../core/models/money.dart';
import '../../../../core/extensions/date_time_extension.dart';
import '../../../../core/models/investment_type.dart';

class WalletOverview extends Equatable {
  final Money balance;
  final Money pendingCredit;
  final Money pendingDebit;

  const WalletOverview({
    required this.balance,
    required this.pendingCredit,
    required this.pendingDebit,
  });

  factory WalletOverview.fromJson(Map<String, dynamic> json) {
    return WalletOverview(
      balance: Money.fromJson(json['balance'] ?? {'amountInKobo': 0}),
      pendingCredit: Money.fromJson(json['pending_credit'] ?? {'amountInKobo': 0}),
      pendingDebit: Money.fromJson(json['pending_debit'] ?? {'amountInKobo': 0}),
    );
  }

  Money get availableBalance => balance + pendingCredit - pendingDebit;
  bool get hasPendingTransactions => !pendingCredit.isZero || !pendingDebit.isZero;

  @override
  List<Object?> get props => [balance, pendingCredit, pendingDebit];
}

class Transaction extends Equatable {
  final String id;
  final String type;
  final Money amount;
  final String description;
  final DateTime timestamp;
  final String status;
  final String currency;
  final String? reference;
  final String? category;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
    required this.status,
    required this.currency,
    this.reference,
    this.category,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final timestamp = DateTime.parse(json['timestamp'] as String).toLocal();
    return Transaction(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: Money.fromJson(json['amount'] ?? {'amountInKobo': 0}),
      description: json['description'] as String,
      timestamp: timestamp,
      status: json['status'] as String,
      currency: json['currency'] as String? ?? 'NGN',
      reference: json['reference'] as String?,
      category: json['category'] as String?,
    );
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isSuccessful => status.toLowerCase() == 'successful';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isCredit => type.toLowerCase() == 'credit';
  bool get isDebit => type.toLowerCase() == 'debit';

  @override
  List<Object?> get props => [
        id,
        type,
        amount,
        description,
        timestamp,
        status,
        currency,
        reference,
        category,
      ];
}

class LoanOverview extends Equatable {
  final Money activeLoanAmount;
  final Money totalRepaid;
  final DateTime? nextRepaymentDate;
  final Money nextRepaymentAmount;
  final Money totalLoansReceived;
  final bool isEligibleForNew;
  final Money maximumEligibleAmount;
  final double interestRate;
  final String loanTermUnit;
  final int loanTerm;

  const LoanOverview({
    required this.activeLoanAmount,
    required this.totalRepaid,
    this.nextRepaymentDate,
    required this.nextRepaymentAmount,
    required this.totalLoansReceived,
    required this.isEligibleForNew,
    required this.maximumEligibleAmount,
    this.interestRate = 0.0,
    this.loanTermUnit = 'months',
    this.loanTerm = 0,
  });

  factory LoanOverview.fromJson(Map<String, dynamic> json) {
    return LoanOverview(
      activeLoanAmount: Money.fromJson(json['active_loan_amount'] ?? {'amountInKobo': 0}),
      totalRepaid: Money.fromJson(json['total_repaid'] ?? {'amountInKobo': 0}),
      nextRepaymentDate: json['next_repayment_date'] != null
          ? DateTime.parse(json['next_repayment_date'] as String).toLocal()
          : null,
      nextRepaymentAmount: Money.fromJson(json['next_repayment_amount'] ?? {'amountInKobo': 0}),
      totalLoansReceived: Money.fromJson(json['total_loans_received'] ?? {'amountInKobo': 0}),
      isEligibleForNew: json['is_eligible_for_new'] as bool? ?? false,
      maximumEligibleAmount: Money.fromJson(json['maximum_eligible_amount'] ?? {'amountInKobo': 0}),
      interestRate: (json['interest_rate'] as num?)?.toDouble() ?? 0.0,
      loanTermUnit: json['loan_term_unit'] as String? ?? 'months',
      loanTerm: json['loan_term'] as int? ?? 0,
    );
  }

  bool get hasActiveLoan => !activeLoanAmount.isZero;
  double get repaymentProgress => hasActiveLoan 
    ? totalRepaid.inNaira / (activeLoanAmount + totalRepaid).inNaira
    : 0.0;
  bool get isRepaymentDue => nextRepaymentDate != null && 
    nextRepaymentDate!.isBefore(DateTime.now());

  @override
  List<Object?> get props => [
        activeLoanAmount,
        totalRepaid,
        nextRepaymentDate,
        nextRepaymentAmount,
        totalLoansReceived,
        isEligibleForNew,
        maximumEligibleAmount,
        interestRate,
        loanTermUnit,
        loanTerm,
      ];
}

class SavingsOverview extends Equatable {
  final Money totalSavings;
  final Money monthlyTarget;
  final Money monthlyProgress;
  final Money yearlyTarget;
  final Money yearlyProgress;
  final Money interestEarned;
  final double interestRate;
  final DateTime lastContributionDate;

  const SavingsOverview({
    required this.totalSavings,
    required this.monthlyTarget,
    required this.monthlyProgress,
    required this.yearlyTarget,
    required this.yearlyProgress,
    required this.interestEarned,
    this.interestRate = 0.0,
    required this.lastContributionDate,
  });

  factory SavingsOverview.fromJson(Map<String, dynamic> json) {
    return SavingsOverview(
      totalSavings: Money.fromJson(json['total_savings'] ?? {'amountInKobo': 0}),
      monthlyTarget: Money.fromJson(json['monthly_target'] ?? {'amountInKobo': 0}),
      monthlyProgress: Money.fromJson(json['monthly_progress'] ?? {'amountInKobo': 0}),
      yearlyTarget: Money.fromJson(json['yearly_target'] ?? {'amountInKobo': 0}),
      yearlyProgress: Money.fromJson(json['yearly_progress'] ?? {'amountInKobo': 0}),
      interestEarned: Money.fromJson(json['interest_earned'] ?? {'amountInKobo': 0}),
      interestRate: (json['interest_rate'] as num?)?.toDouble() ?? 0.0,
      lastContributionDate: json['last_contribution_date'] != null
          ? DateTime.parse(json['last_contribution_date'] as String).toLocal()
          : DateTime.now(),
    );
  }

  double get monthlyProgressPercentage => !monthlyTarget.isZero 
    ? (monthlyProgress.inNaira / monthlyTarget.inNaira * 100).clamp(0, 100)
    : 0.0;

  double get yearlyProgressPercentage => !yearlyTarget.isZero
    ? (yearlyProgress.inNaira / yearlyTarget.inNaira * 100).clamp(0, 100)
    : 0.0;

  bool get isOnTrack => monthlyProgressPercentage >= 
    ((DateTime.now().day / DateTime.now().daysInMonth) * 100);

  @override
  List<Object?> get props => [
        totalSavings,
        monthlyTarget,
        monthlyProgress,
        yearlyTarget,
        yearlyProgress,
        interestEarned,
        interestRate,
        lastContributionDate,
      ];
}

class InvestmentOverview extends Equatable {
  final Money totalInvested;
  final Money currentValue;
  final Money totalReturns;
  final Money pendingReturns;
  final List<Investment> activeInvestments;

  const InvestmentOverview({
    required this.totalInvested,
    required this.currentValue,
    required this.totalReturns,
    required this.pendingReturns,
    required this.activeInvestments,
  });

  factory InvestmentOverview.fromJson(Map<String, dynamic> json) {
    return InvestmentOverview(
      totalInvested: Money.fromJson(json['total_invested'] ?? {'amountInKobo': 0}),
      currentValue: Money.fromJson(json['current_value'] ?? {'amountInKobo': 0}),
      totalReturns: Money.fromJson(json['total_returns'] ?? {'amountInKobo': 0}),
      pendingReturns: Money.fromJson(json['pending_returns'] ?? {'amountInKobo': 0}),
      activeInvestments: (json['active_investments'] as List?)
          ?.map((e) => Investment.fromJson(e))
          .toList() ?? [],
    );
  }

  double get returnOnInvestment => !totalInvested.isZero
    ? ((currentValue - totalInvested).inNaira / totalInvested.inNaira * 100)
    : 0.0;

  double get annualizedReturn {
    if (activeInvestments.isEmpty) return 0.0;
    double totalDays = 0;
    double weightedReturns = 0;
    
    for (final investment in activeInvestments) {
      final days = investment.maturityDate.difference(investment.startDate).inDays;
      totalDays += days;
      weightedReturns += investment.annualizedReturn * days;
    }
    
    return totalDays > 0 ? weightedReturns / totalDays : 0.0;
  }

  @override
  List<Object?> get props => [
        totalInvested,
        currentValue,
        totalReturns,
        pendingReturns,
        activeInvestments,
      ];
}

class Investment extends Equatable {
  final String id;
  final InvestmentType type;
  final Money amount;
  final Money expectedReturn;
  final DateTime maturityDate;
  final DateTime startDate;
  final String status;
  final double interestRate;

  const Investment({
    required this.id,
    required this.type,
    required this.amount,
    required this.expectedReturn,
    required this.maturityDate,
    required this.startDate,
    required this.status,
    this.interestRate = 0.0,
  });

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'] as String,
      type: InvestmentType.values.firstWhere(
        (e) => e.toString() == 'InvestmentType.${json['type']}',
        orElse: () => InvestmentType.other,
      ),
      amount: Money.fromJson(json['amount'] ?? {'amountInKobo': 0}),
      expectedReturn: Money.fromJson(json['expected_return'] ?? {'amountInKobo': 0}),
      maturityDate: DateTime.parse(json['maturity_date'] as String).toLocal(),
      startDate: DateTime.parse(json['start_date'] as String).toLocal(),
      status: json['status'] as String,
      interestRate: (json['interest_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  double get daysToMaturity {
    final now = DateTime.now();
    if (now.isAfter(maturityDate)) return 0;
    return maturityDate.difference(now).inDays.toDouble();
  }

  double get progressPercentage {
    final totalDays = maturityDate.difference(startDate).inDays;
    final elapsedDays = DateTime.now().difference(startDate).inDays;
    return (elapsedDays / totalDays * 100).clamp(0, 100);
  }

  double get annualizedReturn {
    final days = maturityDate.difference(startDate).inDays;
    if (days <= 0) return 0.0;
    
    final totalReturn = (expectedReturn - amount).inNaira;
    return (totalReturn / amount.inNaira) * (365 / days) * 100;
  }

  bool get isMatured => DateTime.now().isAfter(maturityDate);
  bool get isActive => status.toLowerCase() == 'active';

  @override
  List<Object?> get props => [
        id,
        type,
        amount,
        expectedReturn,
        maturityDate,
        startDate,
        status,
        interestRate,
      ];
}

class GuarantorshipOverview extends Equatable {
  final String id;
  final String borrowerName;
  final Money amount;
  final String status;
  final DateTime guaranteedDate;
  final double riskScore;
  final Money? repaidAmount;
  final DateTime? dueDate;

  const GuarantorshipOverview({
    required this.id,
    required this.borrowerName,
    required this.amount,
    required this.status,
    required this.guaranteedDate,
    required this.riskScore,
    this.repaidAmount,
    this.dueDate,
  });

  factory GuarantorshipOverview.fromJson(Map<String, dynamic> json) {
    return GuarantorshipOverview(
      id: json['id'] as String,
      borrowerName: json['borrower_name'] as String,
      amount: Money.fromJson(json['amount'] ?? {'amountInKobo': 0}),
      status: json['status'] as String,
      guaranteedDate: DateTime.parse(json['guaranteed_date'] as String).toLocal(),
      riskScore: (json['risk_score'] as num).toDouble(),
      repaidAmount: json['repaid_amount'] != null
          ? Money.fromJson(json['repaid_amount'])
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String).toLocal()
          : null,
    );
  }

  bool get isDefaulted => status.toLowerCase() == 'defaulted';
  bool get isActive => status.toLowerCase() == 'active';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isCompleted => status.toLowerCase() == 'completed';

  bool get isOverdue => dueDate != null && 
    DateTime.now().isAfter(dueDate!) &&
    status.toLowerCase() != 'completed';

  double get repaymentProgress => repaidAmount != null
    ? (repaidAmount!.inNaira / amount.inNaira * 100).clamp(0, 100)
    : 0.0;

  String get riskLevel {
    if (riskScore <= 0.3) return 'Low';
    if (riskScore <= 0.7) return 'Medium';
    return 'High';
  }

  @override
  List<Object?> get props => [
        id,
        borrowerName,
        amount,
        status,
        guaranteedDate,
        riskScore,
        repaidAmount,
        dueDate,
      ];
}
