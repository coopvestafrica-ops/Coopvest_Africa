// Models for loan eligibility service
class LoanTypeInfo {
  final double interestRate;
  final int durationMonths;

  const LoanTypeInfo({
    required this.interestRate,
    required this.durationMonths,
  });
}

class LoanDetails {
  final double monthlyPayment;
  final double interestRate;
  final int durationMonths;
  final double totalInterest;

  const LoanDetails({
    required this.monthlyPayment,
    required this.interestRate,
    required this.durationMonths,
    required this.totalInterest,
  });

  Map<String, dynamic> toMap() => {
    'monthlyPayment': monthlyPayment,
    'interestRate': interestRate,
    'durationMonths': durationMonths,
    'totalInterest': totalInterest,
  };
}

class LoanEligibilityResult {
  final bool isEligible;
  final String reason;
  final double? maximumAmount;
  final LoanDetails? loanDetails;

  const LoanEligibilityResult({
    required this.isEligible,
    required this.reason,
    this.maximumAmount,
    this.loanDetails,
  });

  Map<String, dynamic> toMap() => {
    'isEligible': isEligible,
    'reason': reason,
    if (maximumAmount != null) 'maximumAmount': maximumAmount,
    if (loanDetails != null) 'loanDetails': loanDetails!.toMap(),
  };
}
