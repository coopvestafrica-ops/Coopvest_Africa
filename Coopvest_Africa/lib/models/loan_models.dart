class LoanTypeInfo {
  final double interestRate;
  final int durationMonths;

  LoanTypeInfo({
    required this.interestRate,
    required this.durationMonths,
  });
}

class LoanDetails {
  final double monthlyPayment;
  final double interestRate;
  final int durationMonths;
  final double totalInterest;

  LoanDetails({
    required this.monthlyPayment,
    required this.interestRate,
    required this.durationMonths,
    required this.totalInterest,
  });
}
