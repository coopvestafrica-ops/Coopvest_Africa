import '../models/loan_application.dart';
import '../models/loan_guarantor.dart';
import '../models/loan_submission_result.dart';
import '../models/rollover_eligibility.dart';
import '../models/rollover_request.dart';

/// Defines the contract for loan-related operations in the application.
/// Implementations should handle network errors and validation appropriately.
abstract class LoanServiceInterface {
  /// Valid loan status values with their descriptions
  static const Map<String, String> validLoanStatuses = {
    'pending': 'Awaiting review',
    'active': 'Active loan',
    'completed': 'Fully repaid',
    'defaulted': 'Payment defaulted',
    'cancelled': 'Application cancelled',
    'rejected': 'Application rejected',
    'rolled_over': 'Rolled over to new loan',
  };

  /// Valid rollover request status values with their descriptions
  static const Map<String, String> validRolloverStatuses = {
    'pending': 'Awaiting guarantor approval',
    'completed': 'Rollover successful',
    'cancelled': 'Request cancelled',
    'rejected': 'Request rejected',
    'expired': 'Request expired',
    'processing': 'Processing rollover',
    'failed': 'Rollover failed',
  };

  /// Maximum lifetime of a rollover request before expiry (in hours)
  static const int rolloverRequestExpiryHours = 72;

  /// Minimum required percentage of current loan that must be paid 
  /// for rollover eligibility
  static const double minPaymentPercentageForRollover = 50.0;

  /// Maximum percentage increase allowed for new loan amount compared
  /// to the original loan amount
  static const double maxLoanIncreasePercentage = 50.0;

  /// Valid loan tenure options in months, sorted in ascending order
  static const List<int> validTenureMonths = [12, 18, 24, 36];

  /// Maximum number of active guarantees a user can have
  static const int maxActiveGuarantees = 3;

  /// Minimum credit score required to be a guarantor
  static const double minGuarantorCreditScore = 600.0;

  /// Maximum percentage of monthly income that can be guaranteed
  static const double maxIncomeGuaranteePercentage = 50.0;
  /// Submits a new loan application and returns the result.
  /// 
  /// Throws:
  /// - [ValidationException] if application data is invalid
  /// - [NetworkException] if there's a connection error
  /// - [AuthException] if user is not authenticated
  Future<LoanSubmissionResult> submitLoanApplication(LoanApplication application);

  /// Retrieves the list of guarantors for a specific loan.
  /// 
  /// [loanId] must be a valid loan identifier.
  /// 
  /// Throws [NotFoundException] if loan is not found
  Future<List<LoanGuarantor>> getLoanGuarantors(String loanId);

  /// Creates a new rollover request for an existing loan.
  /// 
  /// Parameters:
  /// - [oldLoanId]: ID of the existing loan to rollover
  /// - [userId]: ID of the user requesting the rollover
  /// - [newLoanAmount]: Requested amount for the new loan
  /// - [newTenureMonths]: Requested tenure from [validTenureMonths]
  /// - [reason]: Optional reason for requesting rollover
  /// - [notifyGuarantors]: Whether to notify guarantors (default: true)
  /// - [attachments]: Optional list of document URLs
  /// 
  /// The rollover request will:
  /// 1. Validate loan eligibility via [checkRolloverEligibility]
  /// 2. Calculate new loan terms based on [maxLoanIncreasePercentage]
  /// 3. Verify guarantor eligibility for new amount
  /// 4. Create request with 'pending' status
  /// 5. Notify guarantors if requested
  /// 
  /// Throws:
  /// - [ValidationException] if parameters are invalid
  /// - [EligibilityException] if loan is not eligible for rollover
  /// - [LoanException] if request creation fails
  Future<RolloverRequest> createRolloverRequest({
    required String oldLoanId,
    required String userId,
    required double newLoanAmount,
    required int newTenureMonths,
    String? reason,
    bool notifyGuarantors = true,
    List<String>? attachments,
  });

  /// Approves a rollover request from a guarantor.
  /// 
  /// Parameters:
  /// - [requestId]: ID of the rollover request
  /// - [guarantorId]: ID of the guarantor approving the request
  /// - [verificationCode]: Optional OTP/verification code
  /// - [comments]: Optional approval comments
  /// 
  /// The approval process will:
  /// 1. Verify guarantor eligibility hasn't changed
  /// 2. Record approval with timestamp
  /// 3. Check if this completes required approvals
  /// 4. If complete, initiate rollover process
  /// 5. Update request status and notify stakeholders
  /// 
  /// Returns updated [RolloverRequest] with:
  /// - New approval status
  /// - Approval count and total required
  /// - Next steps if not fully approved
  /// - New loan details if fully approved
  /// 
  /// Throws:
  /// - [NotFoundException] if request or guarantor not found
  /// - [ValidationException] if:
  ///   - Guarantor not valid for this request
  ///   - Verification code invalid
  ///   - Request expired (after [rolloverRequestExpiryHours])
  ///   - Already approved by this guarantor
  /// - [LoanException] if approval processing fails
  Future<RolloverRequest> approveRollover({
    required String requestId,
    required String guarantorId,
    String? verificationCode,
    String? comments,
  });

  /// Checks if a loan is eligible for rollover.
  /// 
  /// [loanId] must be a valid loan identifier.
  /// 
  /// Returns [RolloverEligibility] containing eligibility status and requirements
  /// 
  /// Throws [NotFoundException] if loan is not found
  Future<RolloverEligibility> checkRolloverEligibility(String loanId);

  /// Retrieves rollover history for a specific user.
  /// 
  /// [userId] must be a valid user identifier.
  /// 
  /// Returns list of past rollover requests in chronological order
  Future<List<RolloverRequest>> getRolloverHistory(String userId);

  /// Retrieves pending rollover requests for a guarantor.
  /// 
  /// [guarantorId] must be a valid guarantor identifier.
  /// 
  /// Returns list of rollover requests pending approval
  Future<List<RolloverRequest>> getPendingRolloverRequests(String guarantorId);

  /// Updates the status of a loan application.
  /// 
  /// Parameters:
  /// - [loanId]: ID of the loan to update
  /// - [status]: New status for the loan
  /// - [remarks]: Optional remarks about the status change
  /// 
  /// Throws [NotFoundException] if loan is not found
  Future<void> updateLoanStatus({
    required String loanId,
    required String status,
    String? remarks,
  });

  /// Cancels a loan application
  ///
  /// Parameters:
  /// - [loanId]: ID of the loan to cancel
  ///
  /// Throws:
  /// - [NotFoundException] if loan not found
  /// - [ValidationException] if loan cannot be cancelled
  Future<void> cancelLoan(String loanId);

  /// Validates a loan application before submission.
  /// 
  /// Returns true if application is valid, throws [ValidationException] otherwise
  Future<bool> validateLoanApplication(LoanApplication application);

  /// Cancels a rollover request.
  /// 
  /// [requestId] must be a valid rollover request identifier.
  /// 
  /// Throws:
  /// - [NotFoundException] if request not found
  /// - [ValidationException] if request cannot be cancelled
  Future<void> cancelRolloverRequest(String requestId);

  /// Gets detailed information about a loan by its ID.
  /// 
  /// Parameters:
  /// - [loanId]: ID of the loan to fetch
  /// 
  /// Returns a [LoanApplication] containing current loan details
  /// 
  /// Throws:
  /// - [NotFoundException] if loan is not found
  /// - [AuthException] if user lacks permission to view the loan
  Future<LoanApplication> getLoanById(String loanId);

  /// Gets a list of all loans in history.
  /// 
  /// Returns a list of [LoanApplication] objects sorted by creation date.
  /// 
  /// Throws:
  /// - [AuthException] if user is not authenticated
  /// - [ValidationException] if parameters are invalid
  Future<List<LoanApplication>> getLoanHistory();

  /// Validates if a user can be a guarantor for a loan.
  /// 
  /// Parameters:
  /// - [userId]: ID of the potential guarantor
  /// - [loanAmount]: Amount of the loan to guarantee
  /// - [loanTenure]: Loan tenure in months
  /// - [checkCreditScore]: Whether to verify credit score (default: true)
  /// - [checkIncome]: Whether to verify income (default: true)
  /// 
  /// Returns a map containing:
  /// - isEligible: Whether the user can be a guarantor
  /// - maxAmount: Maximum amount they can guarantee
  /// - reason: Reason if not eligible
  /// - metrics: Detailed eligibility metrics
  ///   - creditScore: User's credit score
  ///   - activeGuarantees: Number of active guarantees
  ///   - totalGuaranteed: Total amount guaranteed
  ///   - monthlyIncome: User's monthly income
  /// 
  /// Throws:
  /// - [NotFoundException] if user not found
  /// - [ValidationException] if parameters are invalid
  /// - [LoanException] if eligibility check fails
  Future<Map<String, dynamic>> checkGuarantorEligibility({
    required String userId,
    required double loanAmount,
    required int loanTenure,
    bool checkCreditScore = true,
    bool checkIncome = true,
  });

  /// Gets comprehensive statistics about a user's loan history.
  /// 
  /// [userId] must be a valid user identifier.
  /// 
  /// Returns map containing:
  /// - summary: Overall summary
  ///   - totalLoans: Number of loans taken
  ///   - totalAmount: Total amount borrowed
  ///   - repaymentRate: Percentage of on-time payments
  ///   - averageDaysLate: Average days late for payments
  ///   - defaultCount: Number of defaults
  /// - current: Current loan status
  ///   - activeLoans: Number of active loans
  ///   - totalOutstanding: Total outstanding amount
  ///   - nextPaymentDue: Date of next payment
  /// - history: Historical performance
  ///   - completedLoans: Number of fully repaid loans
  ///   - latePayments: Count of late payments
  ///   - averageLoanAmount: Average loan amount
  ///   - longestLoanTenure: Longest loan tenure in months
  /// - guarantees: Guarantor information
  ///   - activeGuarantees: Number of active guarantees
  ///   - totalGuaranteed: Total amount guaranteed
  ///   - defaultedGuarantees: Number of defaulted guarantees
  Future<Map<String, dynamic>> getUserLoanStatistics(String userId);

  /// Archives a completed or defaulted loan.
  /// 
  /// Parameters:
  /// - [loanId]: ID of the loan to archive
  /// - [reason]: Reason for archiving
  /// - [archivePayments]: Whether to archive payment history (default: true)
  /// - [archiveDocuments]: Whether to archive loan documents (default: true)
  /// 
  /// The archived loan and its related data will be:
  /// 1. Copied to a separate archive collection
  /// 2. Marked as archived in the main collection
  /// 3. Removed from active queries
  /// 4. Still accessible for reporting and audits
  /// 
  /// Throws:
  /// - [NotFoundException] if loan not found
  /// - [ValidationException] if loan status is not 'completed' or 'defaulted'
  /// - [LoanException] if archiving fails
  Future<void> archiveLoan({
    required String loanId,
    required String reason,
    bool archivePayments = true,
    bool archiveDocuments = true,
  });
}
