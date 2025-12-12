import 'transaction_status.dart';

enum TransactionType { 
  saving, 
  loan, 
  contribution, 
  withdrawal,
  transfer,
  investment,
  other;

  bool get isInflow {
    return this == TransactionType.saving || 
           this == TransactionType.loan ||
           this == TransactionType.contribution;
  }

  bool get isOutflow {
    return this == TransactionType.withdrawal ||
           this == TransactionType.investment;
  }

  String get displayName {
    switch (this) {
      case TransactionType.saving:
        return 'Saving';
      case TransactionType.loan:
        return 'Loan';
      case TransactionType.contribution:
        return 'Contribution';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.investment:
        return 'Investment';
      case TransactionType.other:
        return 'Other';
    }
  }
}

enum TransactionCategory {
  food,
  transport,
  shopping,
  bills,
  entertainment,
  investment,
  savings,
  loan,
  withdrawal,
  transfer,
  salary,
  other;

  bool get isIncome {
    return this == TransactionCategory.salary || 
           this == TransactionCategory.loan;
  }

  bool get isExpense {
    return this == TransactionCategory.food ||
           this == TransactionCategory.transport ||
           this == TransactionCategory.shopping ||
           this == TransactionCategory.bills ||
           this == TransactionCategory.entertainment;
  }

  bool get isTransfer {
    return this == TransactionCategory.transfer;
  }

  bool get isInvestment {
    return this == TransactionCategory.investment;
  }

  bool get isSavings {
    return this == TransactionCategory.savings;
  }

  String get displayName {
    switch (this) {
      case TransactionCategory.food:
        return 'Food';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.bills:
        return 'Bills';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.investment:
        return 'Investment';
      case TransactionCategory.savings:
        return 'Savings';
      case TransactionCategory.loan:
        return 'Loan';
      case TransactionCategory.withdrawal:
        return 'Withdrawal';
      case TransactionCategory.transfer:
        return 'Transfer';
      case TransactionCategory.salary:
        return 'Salary';
      case TransactionCategory.other:
        return 'Other';
    }
  }
}

class Transaction {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final String description;
  final TransactionType type;
  final TransactionCategory category;
  final String? reference;
  final TransactionStatus status;
  final List<TransactionStatusUpdate> statusHistory;

  Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    required this.description,
    required this.type,
    required this.category,
    this.reference,
    this.status = TransactionStatus.pending,
    this.statusHistory = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'type': type.toString(),
      'category': category.toString(),
      'reference': reference,
      'status': status.value,
      'statusHistory': statusHistory.map((update) => update.toMap()).toList(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      userId: map['userId'],
      amount: map['amount'].toDouble(),
      date: DateTime.parse(map['date']),
      description: map['description'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.toString() == map['category'],
        orElse: () => TransactionCategory.other,
      ),
      reference: map['reference'],
      status: map['status'] != null 
        ? TransactionStatus.fromString(map['status'])
        : TransactionStatus.pending,
      statusHistory: (map['statusHistory'] as List?)
          ?.map((e) => TransactionStatusUpdate.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Transaction copyWith({
    String? id,
    String? userId,
    double? amount,
    DateTime? date,
    String? description,
    TransactionType? type,
    TransactionCategory? category,
    String? reference,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      reference: reference ?? this.reference,
    );
  }
}
