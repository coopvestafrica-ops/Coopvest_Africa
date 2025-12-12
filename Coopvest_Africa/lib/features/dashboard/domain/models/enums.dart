// Transaction related enums
enum TransactionType {
  deposit,
  withdrawal,
  transfer,
  investment,
  loan,
  unknown,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

// Investment related enums
enum InvestmentType {
  fixedDeposit,
  mutualFund,
  stocks,
  realEstate,
  unknown,
}

enum InvestmentStatus {
  pending,
  active,
  matured,
  liquidated,
  cancelled,
}

// Loan related enums
enum LoanType {
  personal,
  business,
  education,
  mortgage,
  unknown,
}

enum LoanStatus {
  pending,
  active,
  completed,
  defaulted,
  restructured,
}
