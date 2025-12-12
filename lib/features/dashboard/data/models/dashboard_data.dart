import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models/money.dart';
import '../../../../core/models/transaction_type.dart';

extension DateTimeExtension on DateTime {
  int get daysInMonth {
    return DateTime(year, month + 1, 0).day;
  }
}

/// Represents the complete dashboard state including metadata.
class DashboardData extends Equatable {
  static const String currentVersion = '2.0.0';
  final String version;
  final DateTime lastUpdated;
  final WalletOverview walletOverview;
  final List<Transaction> recentTransactions;
  final LoanOverview loanOverview;
  final SavingsOverview savingsOverview;
  final InvestmentOverview investmentOverview;
  final List<GuarantorshipOverview> guarantorships;
  final int notificationCount;
  final List<String> quickActions;

  DashboardData({
    this.version = currentVersion,
    DateTime? lastUpdated,
    required this.walletOverview,
    required this.recentTransactions,
    required this.loanOverview,
    required this.savingsOverview,
    required this.investmentOverview,
    required this.guarantorships,
    this.notificationCount = 0,
    this.quickActions = const [],
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Creates an empty dashboard with default values
  factory DashboardData.empty() {
    return DashboardData(
      walletOverview: WalletOverview(
        balance: Money.zero,
        pendingCredit: Money.zero,
        pendingDebit: Money.zero,
      ),
      recentTransactions: const [],
      loanOverview: LoanOverview(
        activeLoanAmount: Money.zero,
        totalRepaid: Money.zero,
        nextRepaymentAmount: Money.zero,
        totalLoansReceived: Money.zero,
        isEligibleForNew: false,
        maximumEligibleAmount: Money.zero,
      ),
      savingsOverview: SavingsOverview(
        totalSavings: Money.zero,
        monthlyTarget: Money.zero,
        monthlyProgress: 0,
        yearlyTarget: Money.zero,
        yearlyProgress: 0,
        interestEarned: Money.zero,
        expectedInterest: Money.zero,
        goals: const [],
        lastContributionDate: DateTime.now(),
      ),
      investmentOverview: InvestmentOverview(
        totalInvested: Money.zero,
        currentValue: Money.zero,
        totalReturns: Money.zero,
        pendingReturns: Money.zero,
        activeInvestments: const [],
        portfolioAllocation: const {},
        monthlyReturns: const [],
        lastValuationDate: DateTime.now(),
      ),
      guarantorships: const [],
    );
  }

  /// Creates an instance from JSON data with version validation
  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final dataVersion = json['version'] as String? ?? '1.0.0';
    if (dataVersion != currentVersion) {
      // print('Warning: Data version mismatch. Expected $currentVersion, got $dataVersion');
      // TODO: Apply data migration if needed
    }

    return DashboardData(
      version: dataVersion,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
      walletOverview: WalletOverview.fromJson(json['wallet'] ?? {}),
      recentTransactions: (json['transactions'] as List?)
          ?.map((e) => Transaction.fromJson(e))
          .toList() ?? [],
      loanOverview: LoanOverview.fromJson(json['loan'] ?? {}),
      savingsOverview: SavingsOverview.fromJson(json['savings'] ?? {}),
      investmentOverview: InvestmentOverview.fromJson(json['investment'] ?? {}),
      guarantorships: (json['guarantorships'] as List?)
          ?.map((e) => GuarantorshipOverview.fromJson(e))
          .toList() ?? [],
      notificationCount: json['notification_count'] as int? ?? 0,
      quickActions: (json['quick_actions'] as List?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }

  /// Converts the dashboard data to JSON format
  Map<String, dynamic> toJson() => {
    'version': version,
    'last_updated': lastUpdated.toIso8601String(),
    'wallet': walletOverview.toJson(),
    'transactions': recentTransactions.map((t) => t.toJson()).toList(),
    'loan': loanOverview.toJson(),
    'savings': savingsOverview.toJson(),
    'investment': investmentOverview.toJson(),
    'guarantorships': guarantorships.map((g) => g.toJson()).toList(),
    'notification_count': notificationCount,
    'quick_actions': quickActions,
  };

  /// Creates a copy with some fields replaced
  DashboardData copyWith({
    String? version,
    DateTime? lastUpdated,
    WalletOverview? walletOverview,
    List<Transaction>? recentTransactions,
    LoanOverview? loanOverview,
    SavingsOverview? savingsOverview,
    InvestmentOverview? investmentOverview,
    List<GuarantorshipOverview>? guarantorships,
    int? notificationCount,
    List<String>? quickActions,
  }) {
    return DashboardData(
      version: version ?? this.version,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      walletOverview: walletOverview ?? this.walletOverview,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      loanOverview: loanOverview ?? this.loanOverview,
      savingsOverview: savingsOverview ?? this.savingsOverview,
      investmentOverview: investmentOverview ?? this.investmentOverview,
      guarantorships: guarantorships ?? this.guarantorships,
      notificationCount: notificationCount ?? this.notificationCount,
      quickActions: quickActions ?? this.quickActions,
    );
  }

  /// Validates the entire dashboard data structure
  bool validate() {
    try {
      // Version check
      if (version != currentVersion) {
        // print('Version mismatch: $version != $currentVersion');
        return false;
      }

      // Basic data validation
      if (recentTransactions.length > 100) {
        debugPrint('Too many recent transactions');
        return false;
      }

      // Wallet validation
      if (!_validateWallet()) return false;

      // Loan validation
      if (!_validateLoan()) return false;

      // Savings validation
      if (!_validateSavings()) return false;

      // Investment validation
      if (!_validateInvestment()) return false;

      // Transaction validation
      if (!_validateTransactions()) return false;

      // Guarantorship validation
      if (!_validateGuarantorships()) return false;

      return true;
    } catch (e) {
      debugPrint('Validation error: $e');
      return false;
    }
  }

  bool _validateWallet() {
    return walletOverview.balance >= Money.zero &&
           walletOverview.pendingCredit >= Money.zero &&
           walletOverview.pendingDebit >= Money.zero;
  }

  bool _validateLoan() {
    return loanOverview.activeLoanAmount >= Money.zero &&
           loanOverview.totalRepaid >= Money.zero &&
           loanOverview.maximumEligibleAmount >= Money.zero &&
           (loanOverview.nextRepaymentDate == null ||
            loanOverview.nextRepaymentDate!.isAfter(DateTime.now()));
  }

  bool _validateSavings() {
    return savingsOverview.totalSavings >= Money.zero &&
           savingsOverview.monthlyTarget >= Money.zero &&
           savingsOverview.yearlyTarget >= Money.zero &&
           savingsOverview.monthlyProgress >= 0 &&
           savingsOverview.monthlyProgress <= 100 &&
           savingsOverview.yearlyProgress >= 0 &&
           savingsOverview.yearlyProgress <= 100;
  }

  bool _validateInvestment() {
    return investmentOverview.totalInvested >= Money.zero &&
           investmentOverview.currentValue >= Money.zero &&
           investmentOverview.totalReturns >= Money.zero &&
           investmentOverview.pendingReturns >= Money.zero;
  }

  bool _validateTransactions() {
    for (final transaction in recentTransactions) {
      if (transaction.amount.inNaira < 0) return false;
      
      // Validate transaction dates are not in future
      if (transaction.timestamp.isAfter(DateTime.now())) {
        return false;
      }
    }
    return true;
  }

  bool _validateGuarantorships() {
    for (final guarantorship in guarantorships) {
      if (guarantorship.amount.inNaira < 0) return false;
      if (guarantorship.riskScore < 0 || guarantorship.riskScore > 1) return false;
      
      // Validate dates
      if (guarantorship.guaranteedDate.isAfter(DateTime.now())) {
        return false;
      }
      if (guarantorship.expiryDate != null &&
          guarantorship.expiryDate!.isBefore(guarantorship.guaranteedDate)) {
        return false;
      }
    }
    return true;
  }

  // Computed properties
  Money get totalBalance => walletOverview.balance;
  Money get availableBalance => walletOverview.availableBalance;
  Money get totalAssets => totalBalance + savingsOverview.totalSavings + investmentOverview.currentValue;
  Money get totalLiabilities => loanOverview.activeLoanAmount;
  Money get netWorth => totalAssets - totalLiabilities;
  
  bool get hasActiveLoans => loanOverview.hasActiveLoan;
  bool get hasActiveSavingsGoals => savingsOverview.hasActiveGoals;
  bool get hasActiveInvestments => investmentOverview.hasActiveInvestments;
  bool get hasActiveGuarantorships => guarantorships.any((g) => g.isActive);
  
  DateTime get lastTransactionDate => recentTransactions.isNotEmpty 
      ? recentTransactions.first.timestamp 
      : lastUpdated;

  @override
  List<Object?> get props => [
        version,
        lastUpdated,
        walletOverview,
        recentTransactions,
        loanOverview,
        savingsOverview,
        investmentOverview,
        guarantorships,
        notificationCount,
        quickActions,
      ];
}

class WalletOverview extends Equatable {
  final Money balance;
  final Money pendingCredit;
  final Money pendingDebit;
  final DateTime lastUpdated;

  WalletOverview({
    required this.balance,
    required this.pendingCredit,
    required this.pendingDebit,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory WalletOverview.fromJson(Map<String, dynamic> json) {
    return WalletOverview(
      balance: Money.fromJson(json['balance'] ?? {'amount': 0}),
      pendingCredit: Money.fromJson(json['pending_credit'] ?? {'amount': 0}),
      pendingDebit: Money.fromJson(json['pending_debit'] ?? {'amount': 0}),
      lastUpdated: json['last_updated'] != null 
        ? DateTime.parse(json['last_updated'] as String)
        : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'balance': balance.toJson(),
    'pending_credit': pendingCredit.toJson(),
    'pending_debit': pendingDebit.toJson(),
    'last_updated': lastUpdated.toIso8601String(),
  };

  Money get availableBalance => balance - pendingDebit;

  @override
  List<Object?> get props => [balance, pendingCredit, pendingDebit, lastUpdated];
}

enum TransactionStatus {
  pending,
  successful,
  failed,
  reversed,
}

class Transaction extends Equatable {
  final String id;
  final TransactionType type;
  final Money amount;
  final String description;
  final DateTime timestamp;
  final TransactionStatus status;
  final String? reference;
  final Map<String, dynamic>? metadata;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
    required this.status,
    this.reference,
    this.metadata,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${json['type']}',
        orElse: () => TransactionType.transfer,
      ),
      amount: Money.fromJson(json['amount'] ?? {'amount': 0}),
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${json['status']}',
        orElse: () => TransactionStatus.pending,
      ),
      reference: json['reference'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString().split('.').last,
    'amount': amount.toJson(),
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'status': status.toString().split('.').last,
    if (reference != null) 'reference': reference,
    if (metadata != null) 'metadata': metadata,
  };

  bool get isDebit => !type.isInflow;

  bool get isProcessing => status == TransactionStatus.pending;
  bool get isSuccessful => status == TransactionStatus.successful;
  bool get isFailed => status == TransactionStatus.failed;
  bool get isReversed => status == TransactionStatus.reversed;

  @override
  List<Object?> get props => [id, type, amount, description, timestamp, status, reference, metadata];
}

enum LoanStatus {
  none,
  active,
  completed,
  defaulted,
  processing
}

class LoanOverview extends Equatable {
  final Money activeLoanAmount;
  final Money totalRepaid;
  final DateTime? nextRepaymentDate;
  final Money nextRepaymentAmount;
  final Money totalLoansReceived;
  final bool isEligibleForNew;
  final Money maximumEligibleAmount;
  final LoanStatus status;
  final double creditScore;
  final int repaymentStreak;

  const LoanOverview({
    required this.activeLoanAmount,
    required this.totalRepaid,
    this.nextRepaymentDate,
    required this.nextRepaymentAmount,
    required this.totalLoansReceived,
    required this.isEligibleForNew,
    required this.maximumEligibleAmount,
    this.status = LoanStatus.none,
    this.creditScore = 0.0,
    this.repaymentStreak = 0,
  });

  factory LoanOverview.fromJson(Map<String, dynamic> json) {
    return LoanOverview(
      activeLoanAmount: Money.fromJson(json['active_loan_amount'] ?? {'amount': 0}),
      totalRepaid: Money.fromJson(json['total_repaid'] ?? {'amount': 0}),
      nextRepaymentDate: json['next_repayment_date'] != null
          ? DateTime.parse(json['next_repayment_date'] as String)
          : null,
      nextRepaymentAmount: Money.fromJson(json['next_repayment_amount'] ?? {'amount': 0}),
      totalLoansReceived: Money.fromJson(json['total_loans_received'] ?? {'amount': 0}),
      isEligibleForNew: json['is_eligible_for_new'] as bool? ?? false,
      maximumEligibleAmount: Money.fromJson(json['maximum_eligible_amount'] ?? {'amount': 0}),
      status: LoanStatus.values.firstWhere(
        (e) => e.toString() == 'LoanStatus.${json['status']}',
        orElse: () => LoanStatus.none,
      ),
      creditScore: (json['credit_score'] as num?)?.toDouble() ?? 0.0,
      repaymentStreak: json['repayment_streak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'active_loan_amount': activeLoanAmount.toJson(),
    'total_repaid': totalRepaid.toJson(),
    if (nextRepaymentDate != null)
      'next_repayment_date': nextRepaymentDate!.toIso8601String(),
    'next_repayment_amount': nextRepaymentAmount.toJson(),
    'total_loans_received': totalLoansReceived.toJson(),
    'is_eligible_for_new': isEligibleForNew,
    'maximum_eligible_amount': maximumEligibleAmount.toJson(),
    'status': status.toString().split('.').last,
    'credit_score': creditScore,
    'repayment_streak': repaymentStreak,
  };

  bool get hasActiveLoan => status == LoanStatus.active;
  bool get isDefaulted => status == LoanStatus.defaulted;
  int get daysUntilNextRepayment => nextRepaymentDate?.difference(DateTime.now()).inDays ?? 0;
  bool get hasGoodCreditScore => creditScore >= 700;

  @override
  List<Object?> get props => [
        activeLoanAmount,
        totalRepaid,
        nextRepaymentDate,
        nextRepaymentAmount,
        totalLoansReceived,
        isEligibleForNew,
        maximumEligibleAmount,
        status,
        creditScore,
        repaymentStreak,
      ];
}

class SavingsOverview extends Equatable {
  final Money totalSavings;
  final Money monthlyTarget;
  final double monthlyProgress;
  final Money yearlyTarget;
  final double yearlyProgress;
  final Money interestEarned;
  final Money expectedInterest;
  final List<SavingsGoal> goals;
  final DateTime lastContributionDate;
  final int contributionStreak;

  const SavingsOverview({
    required this.totalSavings,
    required this.monthlyTarget,
    required this.monthlyProgress,
    required this.yearlyTarget,
    required this.yearlyProgress,
    required this.interestEarned,
    required this.expectedInterest,
    required this.goals,
    required this.lastContributionDate,
    this.contributionStreak = 0,
  });

  factory SavingsOverview.fromJson(Map<String, dynamic> json) {
    return SavingsOverview(
      totalSavings: Money.fromJson(json['total_savings'] ?? {'amount': 0}),
      monthlyTarget: Money.fromJson(json['monthly_target'] ?? {'amount': 0}),
      monthlyProgress: (json['monthly_progress'] as num?)?.toDouble() ?? 0.0,
      yearlyTarget: Money.fromJson(json['yearly_target'] ?? {'amount': 0}),
      yearlyProgress: (json['yearly_progress'] as num?)?.toDouble() ?? 0.0,
      interestEarned: Money.fromJson(json['interest_earned'] ?? {'amount': 0}),
      expectedInterest: Money.fromJson(json['expected_interest'] ?? {'amount': 0}),
      goals: (json['goals'] as List?)
          ?.map((e) => SavingsGoal.fromJson(e))
          .toList() ?? [],
      lastContributionDate: json['last_contribution_date'] != null
          ? DateTime.parse(json['last_contribution_date'] as String)
          : DateTime.now(),
      contributionStreak: json['contribution_streak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_savings': totalSavings.toJson(),
    'monthly_target': monthlyTarget.toJson(),
    'monthly_progress': monthlyProgress,
    'yearly_target': yearlyTarget.toJson(),
    'yearly_progress': yearlyProgress,
    'interest_earned': interestEarned.toJson(),
    'expected_interest': expectedInterest.toJson(),
    'goals': goals.map((goal) => goal.toJson()).toList(),
    'last_contribution_date': lastContributionDate.toIso8601String(),
    'contribution_streak': contributionStreak,
  };

  bool get hasActiveGoals => goals.isNotEmpty;
  bool get isOnTrackMonthly => monthlyProgress >= (DateTime.now().day / DateTime.now().daysInMonth);
  bool get isOnTrackYearly => yearlyProgress >= (DateTime.now().month / 12);
  
  int get daysSinceLastContribution => 
    DateTime.now().difference(lastContributionDate).inDays;

  double get effectiveInterestRate => 
    totalSavings.inNaira > 0 
      ? (interestEarned.inNaira / totalSavings.inNaira) * 100 
      : 0.0;

  @override
  List<Object?> get props => [
        totalSavings,
        monthlyTarget,
        monthlyProgress,
        yearlyTarget,
        yearlyProgress,
        interestEarned,
        expectedInterest,
        goals,
        lastContributionDate,
        contributionStreak,
      ];
}

enum InvestmentType {
  fixedIncome,
  equity,
  mutualFund,
  realEstate,
  agriculture,
  microfinance,
  other
}

enum InvestmentStatus {
  active,
  matured,
  liquidated,
  defaulted,
  processing
}

class InvestmentOverview extends Equatable {
  final Money totalInvested;
  final Money currentValue;
  final Money totalReturns;
  final Money pendingReturns;
  final List<Investment> activeInvestments;
  final Map<InvestmentType, double> portfolioAllocation;
  final List<MonthlyReturn> monthlyReturns;
  final DateTime lastValuationDate;

  const InvestmentOverview({
    required this.totalInvested,
    required this.currentValue,
    required this.totalReturns,
    required this.pendingReturns,
    required this.activeInvestments,
    required this.portfolioAllocation,
    required this.monthlyReturns,
    required this.lastValuationDate,
  });

  factory InvestmentOverview.fromJson(Map<String, dynamic> json) {
    return InvestmentOverview(
      totalInvested: Money.fromJson(json['total_invested'] ?? {'amount': 0}),
      currentValue: Money.fromJson(json['current_value'] ?? {'amount': 0}),
      totalReturns: Money.fromJson(json['total_returns'] ?? {'amount': 0}),
      pendingReturns: Money.fromJson(json['pending_returns'] ?? {'amount': 0}),
      activeInvestments: (json['active_investments'] as List?)
          ?.map((e) => Investment.fromJson(e))
          .toList() ?? [],
      portfolioAllocation: (json['portfolio_allocation'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          InvestmentType.values.firstWhere(
            (e) => e.toString() == 'InvestmentType.$key',
            orElse: () => InvestmentType.other,
          ),
          (value as num).toDouble(),
        ),
      ) ?? {},
      monthlyReturns: (json['monthly_returns'] as List?)
          ?.map((e) => MonthlyReturn.fromJson(e))
          .toList() ?? [],
      lastValuationDate: json['last_valuation_date'] != null
          ? DateTime.parse(json['last_valuation_date'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'total_invested': totalInvested.toJson(),
    'current_value': currentValue.toJson(),
    'total_returns': totalReturns.toJson(),
    'pending_returns': pendingReturns.toJson(),
    'active_investments': activeInvestments.map((i) => i.toJson()).toList(),
    'portfolio_allocation': portfolioAllocation.map(
      (key, value) => MapEntry(key.toString().split('.').last, value),
    ),
    'monthly_returns': monthlyReturns.map((r) => r.toJson()).toList(),
    'last_valuation_date': lastValuationDate.toIso8601String(),
  };

  double get totalReturnPercentage =>
      totalInvested.inNaira > 0
          ? ((currentValue.inNaira / totalInvested.inNaira) - 1) * 100
          : 0.0;

  bool get hasActiveInvestments => activeInvestments.isNotEmpty;
  
  int get daysSinceLastValuation =>
      DateTime.now().difference(lastValuationDate).inDays;

  Money get unrealizedGains => currentValue - totalInvested;

  @override
  List<Object?> get props => [
        totalInvested,
        currentValue,
        totalReturns,
        pendingReturns,
        activeInvestments,
        portfolioAllocation,
        monthlyReturns,
        lastValuationDate,
      ];
}

class Investment extends Equatable {
  final String id;
  final InvestmentType type;
  final Money amount;
  final Money expectedReturn;
  final DateTime investmentDate;
  final DateTime maturityDate;
  final InvestmentStatus status;
  final double riskLevel;
  final Map<String, dynamic>? metadata;

  const Investment({
    required this.id,
    required this.type,
    required this.amount,
    required this.expectedReturn,
    required this.investmentDate,
    required this.maturityDate,
    required this.status,
    required this.riskLevel,
    this.metadata,
  });

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'] as String,
      type: InvestmentType.values.firstWhere(
        (e) => e.toString() == 'InvestmentType.${json['type']}',
        orElse: () => InvestmentType.other,
      ),
      amount: Money.fromJson(json['amount'] ?? {'amount': 0}),
      expectedReturn: Money.fromJson(json['expected_return'] ?? {'amount': 0}),
      investmentDate: DateTime.parse(json['investment_date'] as String),
      maturityDate: DateTime.parse(json['maturity_date'] as String),
      status: InvestmentStatus.values.firstWhere(
        (e) => e.toString() == 'InvestmentStatus.${json['status']}',
        orElse: () => InvestmentStatus.processing,
      ),
      riskLevel: (json['risk_level'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString().split('.').last,
    'amount': amount.toJson(),
    'expected_return': expectedReturn.toJson(),
    'investment_date': investmentDate.toIso8601String(),
    'maturity_date': maturityDate.toIso8601String(),
    'status': status.toString().split('.').last,
    'risk_level': riskLevel,
    if (metadata != null) 'metadata': metadata,
  };

  int get daysUntilMaturity => maturityDate.difference(DateTime.now()).inDays;
  bool get isMatured => status == InvestmentStatus.matured;
  bool get isActive => status == InvestmentStatus.active;
  double get expectedReturnRate => 
      (expectedReturn.inNaira / amount.inNaira - 1) * 100;
  int get investmentTerm => 
      maturityDate.difference(investmentDate).inDays;

  @override
  List<Object?> get props => [
        id,
        type,
        amount,
        expectedReturn,
        investmentDate,
        maturityDate,
        status,
        riskLevel,
        metadata,
      ];
}

enum GuarantorshipStatus {
  pending,
  active,
  completed,
  defaulted,
  cancelled
}

class SavingsGoal extends Equatable {
  final String id;
  final String name;
  final Money targetAmount;
  final Money currentAmount;
  final DateTime targetDate;
  final bool isCompleted;
  final String? description;
  final DateTime createdDate;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    this.isCompleted = false,
    this.description,
    DateTime? createdDate,
  }) : createdDate = createdDate ?? DateTime.now();

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: Money.fromJson(json['target_amount'] ?? {'amount': 0}),
      currentAmount: Money.fromJson(json['current_amount'] ?? {'amount': 0}),
      targetDate: DateTime.parse(json['target_date'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
      description: json['description'] as String?,
      createdDate: json['created_date'] != null
          ? DateTime.parse(json['created_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'target_amount': targetAmount.toJson(),
    'current_amount': currentAmount.toJson(),
    'target_date': targetDate.toIso8601String(),
    'is_completed': isCompleted,
    if (description != null) 'description': description,
    'created_date': createdDate.toIso8601String(),
  };

  double get progress => currentAmount.inNaira / targetAmount.inNaira;
  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;
  bool get isOverdue => targetDate.isBefore(DateTime.now()) && !isCompleted;
  int get duration => targetDate.difference(createdDate).inDays;

  @override
  List<Object?> get props => [
    id,
    name,
    targetAmount,
    currentAmount,
    targetDate,
    isCompleted,
    description,
    createdDate,
  ];
}

class MonthlyReturn extends Equatable {
  final DateTime month;
  final Money amount;
  final double percentage;

  const MonthlyReturn({
    required this.month,
    required this.amount,
    required this.percentage,
  });

  factory MonthlyReturn.fromJson(Map<String, dynamic> json) {
    return MonthlyReturn(
      month: DateTime.parse(json['month'] as String),
      amount: Money.fromJson(json['amount'] ?? {'amount': 0}),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'month': month.toIso8601String(),
    'amount': amount.toJson(),
    'percentage': percentage,
  };

  @override
  List<Object> get props => [month, amount, percentage];
}

class GuarantorshipOverview extends Equatable {
  final String id;
  final String borrowerName;
  final Money amount;
  final GuarantorshipStatus status;
  final DateTime guaranteedDate;
  final DateTime? expiryDate;
  final double riskScore;
  final String borrowerId;
  final String? loanId;
  final Money? recoveredAmount;
  final DateTime? lastRepaymentDate;

  const GuarantorshipOverview({
    required this.id,
    required this.borrowerName,
    required this.amount,
    required this.status,
    required this.guaranteedDate,
    this.expiryDate,
    required this.riskScore,
    required this.borrowerId,
    this.loanId,
    this.recoveredAmount,
    this.lastRepaymentDate,
  });

  factory GuarantorshipOverview.fromJson(Map<String, dynamic> json) {
    return GuarantorshipOverview(
      id: json['id'] as String,
      borrowerName: json['borrower_name'] as String,
      amount: Money.fromJson(json['amount'] ?? {'amount': 0}),
      status: GuarantorshipStatus.values.firstWhere(
        (e) => e.toString() == 'GuarantorshipStatus.${json['status']}',
        orElse: () => GuarantorshipStatus.pending,
      ),
      guaranteedDate: DateTime.parse(json['guaranteed_date'] as String),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      riskScore: (json['risk_score'] as num).toDouble(),
      borrowerId: json['borrower_id'] as String,
      loanId: json['loan_id'] as String?,
      recoveredAmount: json['recovered_amount'] != null
          ? Money.fromJson(json['recovered_amount'])
          : null,
      lastRepaymentDate: json['last_repayment_date'] != null
          ? DateTime.parse(json['last_repayment_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'borrower_name': borrowerName,
    'amount': amount.toJson(),
    'status': status.toString().split('.').last,
    'guaranteed_date': guaranteedDate.toIso8601String(),
    if (expiryDate != null) 'expiry_date': expiryDate!.toIso8601String(),
    'risk_score': riskScore,
    'borrower_id': borrowerId,
    if (loanId != null) 'loan_id': loanId,
    if (recoveredAmount != null) 'recovered_amount': recoveredAmount!.toJson(),
    if (lastRepaymentDate != null)
      'last_repayment_date': lastRepaymentDate!.toIso8601String(),
  };

  bool get isActive => status == GuarantorshipStatus.active;
  bool get isDefaulted => status == GuarantorshipStatus.defaulted;
  int get guaranteeDuration =>
      DateTime.now().difference(guaranteedDate).inDays;
  bool get isExpired => 
      expiryDate != null && expiryDate!.isBefore(DateTime.now());
  int get daysSinceLastRepayment =>
      lastRepaymentDate != null
          ? DateTime.now().difference(lastRepaymentDate!).inDays
          : 0;

  @override
  List<Object?> get props => [
        id,
        borrowerName,
        amount,
        status,
        guaranteedDate,
        expiryDate,
        riskScore,
        borrowerId,
        loanId,
        recoveredAmount,
        lastRepaymentDate,
      ];
}
