import 'package:equatable/equatable.dart';
import '../../../../core/models/money.dart';

enum TransactionType { deposit, withdrawal, loan, investment, savings }

class TransactionSummary extends Equatable {
  final String id;
  final TransactionType type;
  final Money amount;
  final DateTime date;
  final String description;
  final String? reference;

  const TransactionSummary({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
    this.reference,
  });

  @override
  List<Object?> get props => [id, type, amount, date, description, reference];

  TransactionSummary copyWith({
    String? id,
    TransactionType? type,
    Money? amount,
    DateTime? date,
    String? description,
    String? reference,
  }) {
    return TransactionSummary(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      reference: reference ?? this.reference,
    );
  }
}
