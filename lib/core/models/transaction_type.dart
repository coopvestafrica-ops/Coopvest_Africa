enum TransactionType {
  credit,
  debit,
  transfer,
  investment,
  withdrawal,
  refund,
  other;

  String get displayName {
    switch (this) {
      case TransactionType.credit:
        return 'Credit';
      case TransactionType.debit:
        return 'Debit';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.investment:
        return 'Investment';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.other:
        return 'Other';
    }
  }

  bool get isInflow {
    return this == TransactionType.credit || 
           this == TransactionType.refund;
  }

  bool get isOutflow {
    return this == TransactionType.debit || 
           this == TransactionType.withdrawal;
  }
}
