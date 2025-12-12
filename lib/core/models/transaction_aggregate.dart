class TransactionAggregate {
  final String id;
  final String userId;
  final String period; // daily, weekly, monthly, yearly
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;
  final int transactionCount;
  final Map<String, double> categoryTotals;
  final DateTime createdAt;

  TransactionAggregate({
    required this.id,
    required this.userId,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    required this.transactionCount,
    required this.categoryTotals,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'period': period,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'totalAmount': totalAmount,
    'transactionCount': transactionCount,
    'categoryTotals': categoryTotals,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TransactionAggregate.fromJson(Map<String, dynamic> json) => TransactionAggregate(
    id: json['id'] as String,
    userId: json['userId'] as String,
    period: json['period'] as String,
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: DateTime.parse(json['endDate'] as String),
    totalAmount: (json['totalAmount'] as num).toDouble(),
    transactionCount: json['transactionCount'] as int,
    categoryTotals: Map<String, double>.from(json['categoryTotals'] as Map),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
