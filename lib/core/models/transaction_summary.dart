import '../utils/date_utils.dart';
import 'transaction.dart';

// Re-export types from transaction.dart for convenience and type safety
export 'transaction.dart' show Transaction, TransactionType, TransactionCategory;

class TransactionSummary {
  final double totalIncome;
  final double totalExpense;
  final double netAmount;
  final int totalTransactions;
  final DateTime startDate;
  final DateTime endDate;
  final Map<TransactionType, double> typeDistribution;
  final Map<TransactionCategory, double> categoryDistribution;
  final Map<DateTime, double> trendData;

  TransactionSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netAmount,
    required this.totalTransactions,
    required this.startDate,
    required this.endDate,
    required this.typeDistribution,
    required this.categoryDistribution,
    required this.trendData,
  });

  /// Creates a transaction summary from a list of transactions
  factory TransactionSummary.fromTransactions(
    List<Transaction> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    double totalIncome = 0;
    double totalExpense = 0;
    final typeDistribution = <TransactionType, double>{};
    final categoryDistribution = <TransactionCategory, double>{};
    final trendData = <DateTime, double>{};

    // Initialize trend data with all dates in range
    var currentDate = DateUtils.dateOnly(startDate);
    final lastDate = DateUtils.dateOnly(endDate);
    while (currentDate.isBefore(lastDate) || currentDate.isAtSameMomentAs(lastDate)) {
      trendData[currentDate] = 0;
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Process all transactions
    for (final transaction in transactions) {
      final amount = transaction.amount;
      final type = transaction.type;
      final category = transaction.category;
      final date = DateUtils.dateOnly(transaction.date);

      // Calculate totals
      if (type.isInflow) {
        totalIncome += amount;
      } else if (type.isOutflow) {
        totalExpense += amount.abs();
      }

      // Update distributions
      typeDistribution.update(
        type,
        (value) => value + amount.abs(),
        ifAbsent: () => amount.abs(),
      );

      categoryDistribution.update(
        category,
        (value) => value + amount.abs(),
        ifAbsent: () => amount.abs(),
      );

      // Update trend data
      if (trendData.containsKey(date)) {
        trendData[date] = (trendData[date] ?? 0) + (type.isInflow ? amount : -amount);
      }
    }

    return TransactionSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netAmount: totalIncome - totalExpense,
      totalTransactions: transactions.length,
      startDate: startDate,
      endDate: endDate,
      typeDistribution: typeDistribution,
      categoryDistribution: categoryDistribution,
      trendData: trendData,
    );
  }

  /// Get average daily transaction amount
  double get averageDailyAmount {
    final days = endDate.difference(startDate).inDays + 1;
    return days > 0 ? netAmount / days : 0;
  }

  /// Get average daily income
  double get averageDailyIncome {
    final days = endDate.difference(startDate).inDays + 1;
    return days > 0 ? totalIncome / days : 0;
  }

  /// Get average daily expense
  double get averageDailyExpense {
    final days = endDate.difference(startDate).inDays + 1;
    return days > 0 ? totalExpense / days : 0;
  }

  /// Get average transaction amount
  double get averageTransactionAmount {
    return totalTransactions > 0 
        ? (totalIncome + totalExpense) / totalTransactions 
        : 0;
  }

  /// Get top income categories
  List<MapEntry<TransactionCategory, double>> getTopIncomeCategories([int limit = 5]) {
    final list = categoryDistribution.entries
        .where((e) => e.key.isIncome)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(limit).toList();
  }

  /// Get top expense categories
  List<MapEntry<TransactionCategory, double>> getTopExpenseCategories([int limit = 5]) {
    final list = categoryDistribution.entries
        .where((e) => e.key.isExpense)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(limit).toList();
  }

  /// Get income trend data
  Map<DateTime, double> getIncomeTrend() {
    final incomeTrend = <DateTime, double>{};
    double runningTotal = 0;

    for (final entry in trendData.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
      if (entry.value > 0) {
        runningTotal += entry.value;
        incomeTrend[entry.key] = runningTotal;
      } else {
        incomeTrend[entry.key] = runningTotal;
      }
    }

    return incomeTrend;
  }

  /// Get expense trend data
  Map<DateTime, double> getExpenseTrend() {
    final expenseTrend = <DateTime, double>{};
    double runningTotal = 0;

    for (final entry in trendData.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
      if (entry.value < 0) {
        runningTotal += entry.value.abs();
        expenseTrend[entry.key] = runningTotal;
      } else {
        expenseTrend[entry.key] = runningTotal;
      }
    }

    return expenseTrend;
  }

  /// Get daily net amount trend
  Map<DateTime, double> getDailyNetTrend() {
    return Map.fromEntries(trendData.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  /// Get cumulative net amount trend
  Map<DateTime, double> getCumulativeNetTrend() {
    final cumulativeTrend = <DateTime, double>{};
    double runningTotal = 0;

    for (final entry in trendData.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
      runningTotal += entry.value;
      cumulativeTrend[entry.key] = runningTotal;
    }

    return cumulativeTrend;
  }

  /// Calculate savings rate (income - expense) / income
  double get savingsRate {
    return totalIncome > 0 ? (totalIncome - totalExpense) / totalIncome : 0;
  }

  /// Get highest single-day income
  MapEntry<DateTime, double>? get highestDailyIncome {
    if (trendData.isEmpty) return null;
    return trendData.entries
        .where((e) => e.value > 0)
        .reduce((a, b) => a.value > b.value ? a : b);
  }

  /// Get highest single-day expense
  MapEntry<DateTime, double>? get highestDailyExpense {
    if (trendData.isEmpty) return null;
    return trendData.entries
        .where((e) => e.value < 0)
        .reduce((a, b) => a.value.abs() > b.value.abs() ? a : b);
  }

  /// Get month-over-month growth rate
  double? getMonthOverMonthGrowth() {
    if (endDate.difference(startDate).inDays < 60) return null;

    final monthlyTotals = <int, double>{};
    for (final entry in trendData.entries) {
      final yearMonth = entry.key.year * 100 + entry.key.month;
      monthlyTotals[yearMonth] = (monthlyTotals[yearMonth] ?? 0) + entry.value;
    }

    if (monthlyTotals.length < 2) return null;

    final sortedMonths = monthlyTotals.keys.toList()..sort();
    final currentMonth = monthlyTotals[sortedMonths.last] ?? 0;
    final previousMonth = monthlyTotals[sortedMonths[sortedMonths.length - 2]] ?? 0;

    return previousMonth != 0 ? (currentMonth - previousMonth) / previousMonth : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'netAmount': netAmount,
      'totalTransactions': totalTransactions,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'typeDistribution': typeDistribution.map((k, v) => MapEntry(k.toString(), v)),
      'categoryDistribution': categoryDistribution.map((k, v) => MapEntry(k.toString(), v)),
      'trendData': trendData.map((k, v) => MapEntry(k.toIso8601String(), v)),
    };
  }

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    try {
      return TransactionSummary(
        totalIncome: (json['totalIncome'] as num).toDouble(),
        totalExpense: (json['totalExpense'] as num).toDouble(),
        netAmount: (json['netAmount'] as num).toDouble(),
        totalTransactions: (json['totalTransactions'] as num).toInt(),
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        typeDistribution: (json['typeDistribution'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(
            TransactionType.values.firstWhere(
              (e) => e.toString() == k,
              orElse: () => TransactionType.other,
            ),
            (v as num).toDouble(),
          ),
        ) ?? {},
        categoryDistribution: (json['categoryDistribution'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(
            TransactionCategory.values.firstWhere(
              (e) => e.toString() == k,
              orElse: () => TransactionCategory.other,
            ),
            (v as num).toDouble(),
          ),
        ) ?? {},
        trendData: (json['trendData'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(DateTime.parse(k), (v as num).toDouble()),
        ) ?? {},
      );
    } catch (e) {
      throw FormatException('Invalid JSON format for TransactionSummary: $e');
    }
  }
}
