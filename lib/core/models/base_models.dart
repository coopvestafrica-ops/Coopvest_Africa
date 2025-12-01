import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String type;
  final double amount;
  final String status;
  final String? reference;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    this.reference,
    required this.createdAt,
    this.metadata,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      type: map['type'],
      amount: map['amount'].toDouble(),
      status: map['status'],
      reference: map['reference'],
      createdAt: DateTime.parse(map['createdAt']),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'status': status,
      'reference': reference,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [id, type, amount, status, reference, createdAt, metadata];
}

class Document extends Equatable {
  final String id;
  final String type;
  final String url;
  final String status;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;

  const Document({
    required this.id,
    required this.type,
    required this.url,
    required this.status,
    required this.createdAt,
    this.verifiedAt,
    this.verifiedBy,
  });

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      type: map['type'],
      url: map['url'],
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
      verifiedAt: map['verifiedAt'] != null ? DateTime.parse(map['verifiedAt']) : null,
      verifiedBy: map['verifiedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'url': url,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
    };
  }

  @override
  List<Object?> get props => [id, type, url, status, createdAt, verifiedAt, verifiedBy];
}
