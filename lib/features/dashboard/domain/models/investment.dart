import 'package:equatable/equatable.dart';
import '../../../../core/models/money.dart';

enum InvestmentStatus { active, matured, terminated }
enum InvestmentType { fixed, flexible }

class Investment extends Equatable {
  final String id;
  final String name;
  final InvestmentType type;
  final InvestmentStatus status;
  final Money principal;
  final Money returns;
  final double interestRate;
  final DateTime startDate;
  final DateTime maturityDate;

  const Investment({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.principal,
    required this.returns,
    required this.interestRate,
    required this.startDate,
    required this.maturityDate,
  });

  @override
  List<Object> get props => [
    id,
    name,
    type,
    status,
    principal,
    returns,
    interestRate,
    startDate,
    maturityDate,
  ];

  Investment copyWith({
    String? id,
    String? name,
    InvestmentType? type,
    InvestmentStatus? status,
    Money? principal,
    Money? returns,
    double? interestRate,
    DateTime? startDate,
    DateTime? maturityDate,
  }) {
    return Investment(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      principal: principal ?? this.principal,
      returns: returns ?? this.returns,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      maturityDate: maturityDate ?? this.maturityDate,
    );
  }
}
