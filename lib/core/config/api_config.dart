class ApiConfig {
  static const String baseUrl = 'https://api.coopvest.africa/v1';
  
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String staffLogin = '/auth/staff/login';
  static const String register = '/auth/register';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String verifyPhone = '/auth/verify-phone';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String settings = '/auth/settings';
  static const String sessions = '/auth/sessions';
  static const String deviceSettings = '/auth/device-settings';
  static const String biometrics = '/auth/biometrics';
  static const String biometricLogin = '/auth/biometric-login';
  static const String verifyMfa = '/auth/verify-mfa';
  
  // User endpoints
  static const String currentUser = '/auth/me';
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/profile/update';
  static const String changePassword = '/user/change-password';
  
  // Loan endpoints
  static const String loans = '/loans';
  static const String loanProducts = '/loans/products';
  static const String loanApplication = '/loans/apply';
  static const String loanDetails = '/loans/'; // Append loan ID
  static const String loanRepayment = '/loans/repayment';
  static const String loanRequirements = '/loans/requirements';
  static const String loanProjection = '/loans/projection';
  static const String loanEligibility = '/loans/eligibility';
  
  // Loan type specific endpoints
  static const String quickLoan = '/loans/types/quick';
  static const String flexiLoan = '/loans/types/flexi';
  static const String stableLoan = '/loans/types/stable';
  static const String premiumLoan = '/loans/types/premium';
  static const String maxiLoan = '/loans/types/maxi';

  // Document endpoints
  static const String documents = '/documents';
  static const String uploadDocument = '/documents/upload';
  static const String verifyDocument = '/documents/verify';
  static const String loanDocuments = '/loans/documents';
  static const String uploadLoanDocument = '/loans/documents/upload';
  static const String verifyLoanDocument = '/loans/documents/verify';

  // Guarantor endpoints
  static const String guarantors = '/guarantors';
  static const String guarantorRequests = '/guarantors/requests';
  static const String guarantorApproval = '/guarantors/approve';
  static const String guarantorScan = '/guarantors/scan';
  static const String guarantorEligibility = '/guarantors/eligibility';

  // Investment endpoints
  static const String investments = '/investments';
  static const String investmentProducts = '/investments/products';
  static const String createInvestment = '/investments/create';
  static const String investmentDetails = '/investments/'; // Append investment ID
  static const String investmentReturns = '/investments/returns';
  static const String investmentProjection = '/investments/projection';

  // Savings endpoints
  static const String savings = '/savings';
  static const String savingsProducts = '/savings/products';
  static const String createSavings = '/savings/create';
  static const String savingsTransactions = '/savings/transactions';
  static const String savingsGoals = '/savings/goals';
  static const String savingsWithdrawal = '/savings/withdraw';

  // Wallet endpoints
  static const String wallet = '/wallet';
  static const String walletBalance = '/wallet/balance';
  static const String fundWallet = '/wallet/fund';
  static const String withdrawFunds = '/wallet/withdraw';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletStatement = '/wallet/statement';

  // Transaction endpoints
  static const String transactions = '/transactions';
  static const String transactionHistory = '/transactions/history';
  static const String verifyTransaction = '/transactions/verify';
  static const String transactionReceipt = '/transactions/receipt';

  // Referral endpoints
  static const String referrals = '/referrals';
  static const String referralStats = '/referrals/stats';
  static const String referralEarnings = '/referrals/earnings';
  static const String referralWithdrawal = '/referrals/withdraw';
  static const String referralInvite = '/referrals/invite';

  // Contribution endpoints
  static const String contributions = '/contributions';
  static const String contributionHistory = '/contributions/history';
  static const String scheduledContributions = '/contributions/scheduled';
  static const String contributionRates = '/contributions/rates';
  static const String contributionProjection = '/contributions/projection';

  // Notification endpoints
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notifications/settings';
  static const String markNotificationRead = '/notifications/mark-read';

  // Support endpoints
  static const String support = '/support';
  static const String createTicket = '/support/tickets/create';
  static const String ticketDetails = '/support/tickets/'; // Append ticket ID
  static const String faqs = '/support/faqs';
}
