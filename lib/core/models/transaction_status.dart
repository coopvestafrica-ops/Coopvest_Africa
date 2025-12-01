enum TransactionStatus {
  pending('pending'),
  processing('processing'),
  completed('completed'),
  failed('failed'),
  cancelled('cancelled'),
  refunded('refunded');

  final String value;
  const TransactionStatus(this.value);

  static TransactionStatus fromString(String status) {
    return TransactionStatus.values.firstWhere(
      (e) => e.value == status.toLowerCase(),
      orElse: () => throw ArgumentError('Invalid transaction status: $status'),
    );
  }

  bool get isTerminal => 
    this == TransactionStatus.completed || 
    this == TransactionStatus.failed || 
    this == TransactionStatus.cancelled ||
    this == TransactionStatus.refunded;

  bool get isSuccess => this == TransactionStatus.completed;
  
  bool get canRetry => 
    this == TransactionStatus.failed || 
    this == TransactionStatus.cancelled;

  bool get canRefund => this == TransactionStatus.completed;
}

class TransactionStatusUpdate {
  final TransactionStatus status;
  final String? reason;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  TransactionStatusUpdate({
    required this.status,
    this.reason,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'status': status.value,
      'reason': reason,
      'metadata': metadata,
      'timestamp': timestamp,
    };
  }

  static TransactionStatusUpdate fromMap(Map<String, dynamic> map) {
    return TransactionStatusUpdate(
      status: TransactionStatus.fromString(map['status']),
      reason: map['reason'],
      metadata: map['metadata'],
      timestamp: map['timestamp'],
    );
  }
}
