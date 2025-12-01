class LoanConfig {
  static const Map<String, Map<String, dynamic>> loanTypes = {
    'Quick Loan': {'duration': 4, 'interest': 7.5},
    'Flexi Loan': {'duration': 6, 'interest': 7},
    'Stable Loan (12 months)': {'duration': 12, 'interest': 5},
    'Stable Loan (18 months)': {'duration': 18, 'interest': 7},
    'Premium Loan': {'duration': 24, 'interest': 14},
    'Maxi Loan': {'duration': 36, 'interest': 19},
  };
}
