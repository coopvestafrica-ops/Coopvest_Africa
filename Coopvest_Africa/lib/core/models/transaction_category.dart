enum TransactionCategory {
  salary,
  bonus,
  investment,
  savings,
  withdrawal,
  bills,
  groceries,
  transport,
  entertainment,
  health,
  education,
  loan,
  transfer,
  other;

  String get displayName {
    switch (this) {
      case TransactionCategory.salary:
        return 'Salary';
      case TransactionCategory.bonus:
        return 'Bonus';
      case TransactionCategory.investment:
        return 'Investment';
      case TransactionCategory.savings:
        return 'Savings';
      case TransactionCategory.withdrawal:
        return 'Withdrawal';
      case TransactionCategory.bills:
        return 'Bills';
      case TransactionCategory.groceries:
        return 'Groceries';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.health:
        return 'Health';
      case TransactionCategory.education:
        return 'Education';
      case TransactionCategory.loan:
        return 'Loan';
      case TransactionCategory.transfer:
        return 'Transfer';
      case TransactionCategory.other:
        return 'Other';
    }
  }

  bool get isIncome {
    return this == TransactionCategory.salary || 
           this == TransactionCategory.bonus;
  }

  bool get isExpense {
    return this == TransactionCategory.bills ||
           this == TransactionCategory.groceries ||
           this == TransactionCategory.transport ||
           this == TransactionCategory.entertainment ||
           this == TransactionCategory.health ||
           this == TransactionCategory.education;
  }

  bool get isTransfer {
    return this == TransactionCategory.transfer;
  }

  bool get isInvestment {
    return this == TransactionCategory.investment;
  }
}
