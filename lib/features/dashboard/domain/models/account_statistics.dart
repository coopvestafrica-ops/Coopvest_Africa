import 'package:equatable/equatable.dart';
import '../../../../core/models/money.dart';

/// Represents the statistical data and metrics for a user's account
/// including transaction history, investment performance, loan status,
/// and credit scoring information.
///
/// Key features:
/// * Transaction tracking
/// * Investment performance metrics
/// * Loan and credit status
/// * Risk assessment
/// * Account activity monitoring
/// * Financial health indicators
/// 
/// Example:
/// ```dart
/// final stats = AccountStatistics(
///   totalTransactions: 15,
///   activeLoans: 1,
///   activeInvestments: 2,
///   totalSavings: Money.fromNaira(50000),
///   totalInvestments: Money.fromNaira(100000),
///   totalLoanBalance: Money.fromNaira(30000),
///   creditScore: 750,
///   guaranteeCount: 0,
/// );
/// 
/// if (stats.isLowRisk && stats.isGoodCreditScore) {
///   // Eligible for premium features
/// }
/// ```
class AccountStatistics extends Equatable {
  /// Total number of transactions performed by the user
  final int totalTransactions;
  
  /// Number of active loans
  final int activeLoans;
  
  /// Number of active investments
  final int activeInvestments;
  
  /// Total amount in savings
  final Money totalSavings;
  
  /// Total amount in investments
  final Money totalInvestments;
  
  /// Total outstanding loan balance
  final Money totalLoanBalance;
  
  /// Credit score (range: 0-850)
  final double creditScore;
  
  /// Number of loans the user is guaranteeing
  final int guaranteeCount;

  /// Creates a new instance of AccountStatistics
  /// 
  /// All parameters are required and represent the current state of the user's account.
  /// [creditScore] must be between 0 and 850.
  const AccountStatistics({
    required this.totalTransactions,
    required this.activeLoans,
    required this.activeInvestments,
    required this.totalSavings,
    required this.totalInvestments,
    required this.totalLoanBalance,
    required this.creditScore,
    required this.guaranteeCount,
  }) : assert(creditScore >= minCreditScore && creditScore <= maxCreditScore, 
         'Credit score must be between $minCreditScore and $maxCreditScore');

  @override
  List<Object> get props => [
    totalTransactions,
    activeLoans,
    activeInvestments,
    totalSavings,
    totalInvestments,
    totalLoanBalance,
    creditScore,
    guaranteeCount,
  ];

  factory AccountStatistics.empty() {
    return AccountStatistics(
      totalTransactions: 0,
      activeLoans: 0,
      activeInvestments: 0,
      totalSavings: Money.zero,
      totalInvestments: Money.zero,
      totalLoanBalance: Money.zero,
      creditScore: 0.0,
      guaranteeCount: 0,
    );
  }

  AccountStatistics copyWith({
    int? totalTransactions,
    int? activeLoans,
    int? activeInvestments,
    Money? totalSavings,
    Money? totalInvestments,
    Money? totalLoanBalance,
    double? creditScore,
    int? guaranteeCount,
  }) {
    return AccountStatistics(
      totalTransactions: totalTransactions ?? this.totalTransactions,
      activeLoans: activeLoans ?? this.activeLoans,
      activeInvestments: activeInvestments ?? this.activeInvestments,
      totalSavings: totalSavings ?? this.totalSavings,
      totalInvestments: totalInvestments ?? this.totalInvestments,
      totalLoanBalance: totalLoanBalance ?? this.totalLoanBalance,
      creditScore: creditScore?.clamp(0.0, 850.0) ?? this.creditScore,
      guaranteeCount: guaranteeCount ?? this.guaranteeCount,
    );
  }

  // Factory constructor to create AccountStatistics from JSON
  factory AccountStatistics.fromJson(Map<String, dynamic> json) {
    final rawScore = (json['creditScore'] as num?)?.toDouble() ?? 0.0;
    final clampedScore = rawScore.clamp(minCreditScore, maxCreditScore);
    
    return AccountStatistics(
      totalTransactions: json['totalTransactions'] as int? ?? 0,
      activeLoans: json['activeLoans'] as int? ?? 0,
      activeInvestments: json['activeInvestments'] as int? ?? 0,
      totalSavings: Money.fromJson(json['totalSavings'] as Map<String, dynamic>? ?? {'amountInKobo': 0}),
      totalInvestments: Money.fromJson(json['totalInvestments'] as Map<String, dynamic>? ?? {'amountInKobo': 0}),
      totalLoanBalance: Money.fromJson(json['totalLoanBalance'] as Map<String, dynamic>? ?? {'amountInKobo': 0}),
      creditScore: clampedScore,
      guaranteeCount: json['guaranteeCount'] as int? ?? 0,
    );
  }

  // Convert AccountStatistics to JSON
  Map<String, dynamic> toJson() => {
    'totalTransactions': totalTransactions,
    'activeLoans': activeLoans,
    'activeInvestments': activeInvestments,
    'totalSavings': totalSavings.toJson(),
    'totalInvestments': totalInvestments.toJson(),
    'totalLoanBalance': totalLoanBalance.toJson(),
    'creditScore': creditScore,
    'guaranteeCount': guaranteeCount,
  };

  // Computed properties
  bool get hasActiveLoan => activeLoans > 0;
  bool get hasActiveInvestment => activeInvestments > 0;
  bool get hasGuarantees => guaranteeCount > 0;

  // Credit score ranges based on industry standards
  bool get isExcellentCreditScore => creditScore >= 800;
  bool get isGoodCreditScore => creditScore >= 670 && creditScore < 800;
  bool get isFairCreditScore => creditScore >= 580 && creditScore < 670;
  bool get isPoorCreditScore => creditScore < 580;

  // Financial health indicators
  Money get totalAssets => totalSavings + totalInvestments;
  Money get netWorth => totalAssets - totalLoanBalance;
  bool get isPositiveNetWorth => netWorth > Money.zero;
  
  // Activity indicators
  bool get isActive => totalTransactions > 0;
  double get averageTransactionsPerLoan => 
    activeLoans > 0 ? totalTransactions / activeLoans : 0.0;
  double get averageTransactionsPerInvestment => 
    activeInvestments > 0 ? totalTransactions / activeInvestments : 0.0;

  // Static constants for credit score ranges
  static const double maxCreditScore = 850.0;
  static const double minCreditScore = 0.0;
  static const double excellentCreditScoreThreshold = 800.0;
  static const double goodCreditScoreThreshold = 670.0;
  static const double fairCreditScoreThreshold = 580.0;

  // Risk assessment
  bool get isHighRisk => 
    isPoorCreditScore || 
    (totalLoanBalance > totalAssets * 0.8) || 
    (activeLoans > 2 && guaranteeCount > 1);

  bool get isMediumRisk =>
    isFairCreditScore || 
    (totalLoanBalance > totalAssets * 0.5) ||
    (activeLoans > 1 && guaranteeCount > 0);

  bool get isLowRisk =>
    (isGoodCreditScore || isExcellentCreditScore) &&
    totalLoanBalance < totalAssets * 0.3 &&
    activeLoans <= 1 &&
    guaranteeCount <= 1;

  // Investment performance
  double get investmentToSavingsRatio =>
    totalSavings > Money.zero ? 
      totalInvestments.inNaira / totalSavings.inNaira : 0.0;

  double get loanToAssetRatio =>
    totalAssets > Money.zero ?
      totalLoanBalance.inNaira / totalAssets.inNaira : 0.0;

  // Account activity level
  AccountActivityLevel get activityLevel {
    if (totalTransactions > 20) return AccountActivityLevel.high;
    if (totalTransactions > 10) return AccountActivityLevel.medium;
    if (totalTransactions > 0) return AccountActivityLevel.low;
    return AccountActivityLevel.inactive;
  }

  // Validation methods
  bool validateTransactionCounts() =>
    totalTransactions >= 0 &&
    activeLoans >= 0 &&
    activeInvestments >= 0 &&
    guaranteeCount >= 0;

  bool validateMoneyAmounts() =>
    totalSavings >= Money.zero &&
    totalInvestments >= Money.zero &&
    totalLoanBalance >= Money.zero;

  bool validateCreditScore() =>
    creditScore >= minCreditScore && creditScore <= maxCreditScore;

  bool isValid() =>
    validateTransactionCounts() &&
    validateMoneyAmounts() &&
    validateCreditScore();
}

// Account activity level enum
enum AccountActivityLevel {
  high,
  medium,
  low,
  inactive;

  bool get isActive => this != AccountActivityLevel.inactive;
}
