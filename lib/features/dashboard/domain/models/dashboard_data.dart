import 'package:equatable/equatable.dart';
import '../../../../core/models/money.dart';
import 'enums.dart';

class DashboardData extends Equatable {
  final Money balance;
  final Money savingsTotal;
  final Money investmentsTotal;
  final Money loansTotal;
  final List<TransactionSummary> recentTransactions;
  final List<Investment> activeInvestments;
  final List<Loan> activeLoans;
  final AccountStatistics statistics;

  const DashboardData({
    required this.balance,
    required this.savingsTotal,
    required this.investmentsTotal,
    required this.loansTotal,
    required this.recentTransactions,
    required this.activeInvestments,
    required this.activeLoans,
    required this.statistics,
  });

  factory DashboardData.empty() {
    return DashboardData(
      balance: Money.zero,
      savingsTotal: Money.zero,
      investmentsTotal: Money.zero,
      loansTotal: Money.zero,
      recentTransactions: const [],
      activeInvestments: const [],
      activeLoans: const [],
      statistics: AccountStatistics.empty(),
    );
  }

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    try {
      return DashboardData(
        balance: Money.fromJson(json['balance'] as Map<String, dynamic>),
        savingsTotal: Money.fromJson(json['savingsTotal'] as Map<String, dynamic>),
        investmentsTotal: Money.fromJson(json['investmentsTotal'] as Map<String, dynamic>),
        loansTotal: Money.fromJson(json['loansTotal'] as Map<String, dynamic>),
        recentTransactions: (json['recentTransactions'] as List?)
            ?.map((e) => TransactionSummary.fromJson(e as Map<String, dynamic>))
            .toList() ?? [],
        activeInvestments: (json['activeInvestments'] as List?)
            ?.map((e) => Investment.fromJson(e as Map<String, dynamic>))
            .toList() ?? [],
        activeLoans: (json['activeLoans'] as List?)
            ?.map((e) => Loan.fromJson(e as Map<String, dynamic>))
            .toList() ?? [],
        statistics: AccountStatistics.fromJson(
          json['statistics'] as Map<String, dynamic>? ?? {},
        ),
      );
    } catch (e) {
      return DashboardData.empty();
    }
  }

  Map<String, dynamic> toJson() => {
    'balance': balance,
    'savingsTotal': savingsTotal,
    'investmentsTotal': investmentsTotal,
    'loansTotal': loansTotal,
    'recentTransactions': recentTransactions.map((e) => e.toJson()).toList(),
    'activeInvestments': activeInvestments.map((e) => e.toJson()).toList(),
    'activeLoans': activeLoans.map((e) => e.toJson()).toList(),
    'statistics': statistics.toJson(),
  };

  @override
  List<Object?> get props => [
    balance,
    savingsTotal,
    investmentsTotal,
    loansTotal,
    recentTransactions,
    activeInvestments,
    activeLoans,
    statistics,
  ];
}

class TransactionSummary extends Equatable {
  final String id;
  final Money amount;
  final String description;
  final DateTime date;
  final TransactionType type;
  final TransactionStatus status;

  const TransactionSummary({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.type,
    required this.status,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      id: json['id'] as String? ?? '',
      amount: Money.fromJson(json['amount'] as Map<String, dynamic>),
      description: json['description'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? ''),
        orElse: () => TransactionType.unknown,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? ''),
        orElse: () => TransactionStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'description': description,
    'date': date.toIso8601String(),
    'type': type.name,
    'status': status.name,
  };

  @override
  List<Object?> get props => [id, amount, description, date, type, status];
}

class Investment extends Equatable {
  final String id;
  final Money amount;
  final Money returns;
  final DateTime startDate;
  final DateTime maturityDate;
  final InvestmentType type;
  final InvestmentStatus status;

  const Investment({
    required this.id,
    required this.amount,
    required this.returns,
    required this.startDate,
    required this.maturityDate,
    required this.type,
    required this.status,
  });

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'] as String? ?? '',
      amount: Money.fromJson(json['amount'] as Map<String, dynamic>),
      returns: Money.fromJson(json['returns'] as Map<String, dynamic>),
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
      maturityDate: DateTime.tryParse(json['maturityDate'] as String? ?? '') ?? DateTime.now(),
      type: InvestmentType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? ''),
        orElse: () => InvestmentType.unknown,
      ),
      status: InvestmentStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? ''),
        orElse: () => InvestmentStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'returns': returns,
    'startDate': startDate.toIso8601String(),
    'maturityDate': maturityDate.toIso8601String(),
    'type': type.name,
    'status': status.name,
  };

  @override
  List<Object?> get props => [
    id,
    amount,
    returns,
    startDate,
    maturityDate,
    type,
    status,
  ];
}

class Loan extends Equatable {
  final String id;
  final Money amount;
  final Money balance;
  final DateTime disbursementDate;
  final DateTime dueDate;
  final LoanType type;
  final LoanStatus status;

  const Loan({
    required this.id,
    required this.amount,
    required this.balance,
    required this.disbursementDate,
    required this.dueDate,
    required this.type,
    required this.status,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String? ?? '',
      amount: Money.fromJson(json['amount'] as Map<String, dynamic>),
      balance: Money.fromJson(json['balance'] as Map<String, dynamic>),
      disbursementDate: DateTime.tryParse(json['disbursementDate'] as String? ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(json['dueDate'] as String? ?? '') ?? DateTime.now(),
      type: LoanType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? ''),
        orElse: () => LoanType.unknown,
      ),
      status: LoanStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? ''),
        orElse: () => LoanStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'balance': balance,
    'disbursementDate': disbursementDate.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'type': type.name,
    'status': status.name,
  };

  @override
  List<Object?> get props => [
    id,
    amount,
    balance,
    disbursementDate,
    dueDate,
    type,
    status,
  ];
}

class AccountStatistics extends Equatable {
  final int totalTransactions;
  final int completedInvestments;
  final int activeLoans;
  final double savingsGrowthRate;
  final double investmentReturnsRate;
  final double loanRepaymentRate;

  const AccountStatistics({
    required this.totalTransactions,
    required this.completedInvestments,
    required this.activeLoans,
    required this.savingsGrowthRate,
    required this.investmentReturnsRate,
    required this.loanRepaymentRate,
  });

  factory AccountStatistics.empty() {
    return const AccountStatistics(
      totalTransactions: 0,
      completedInvestments: 0,
      activeLoans: 0,
      savingsGrowthRate: 0.0,
      investmentReturnsRate: 0.0,
      loanRepaymentRate: 0.0,
    );
  }

  factory AccountStatistics.fromJson(Map<String, dynamic> json) {
    return AccountStatistics(
      totalTransactions: json['totalTransactions'] as int? ?? 0,
      completedInvestments: json['completedInvestments'] as int? ?? 0,
      activeLoans: json['activeLoans'] as int? ?? 0,
      savingsGrowthRate: (json['savingsGrowthRate'] as num?)?.toDouble() ?? 0.0,
      investmentReturnsRate: (json['investmentReturnsRate'] as num?)?.toDouble() ?? 0.0,
      loanRepaymentRate: (json['loanRepaymentRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalTransactions': totalTransactions,
    'completedInvestments': completedInvestments,
    'activeLoans': activeLoans,
    'savingsGrowthRate': savingsGrowthRate,
    'investmentReturnsRate': investmentReturnsRate,
    'loanRepaymentRate': loanRepaymentRate,
  };

  @override
  List<Object?> get props => [
    totalTransactions,
    completedInvestments,
    activeLoans,
    savingsGrowthRate,
    investmentReturnsRate,
    loanRepaymentRate,
  ];
}


