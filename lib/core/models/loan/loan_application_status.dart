/// Status values for loan applications throughout their lifecycle.
/// Aligns with the valid status values defined in LoanServiceInterface.
enum LoanApplicationStatus {
  initial,        // Initial state before submission
  submitting,     // Application is being submitted
  pending,        // Awaiting review
  active,         // Active loan
  completed,      // Fully repaid
  defaulted,      // Payment defaulted
  cancelled,      // Application cancelled
  rejected,       // Application rejected
  rolledOver;     // Rolled over to new loan

  /// Returns a human-readable description of the status
  String get description {
    switch (this) {
      case LoanApplicationStatus.initial:
        return 'Not submitted';
      case LoanApplicationStatus.submitting:
        return 'Submitting application';
      case LoanApplicationStatus.pending:
        return 'Awaiting review';
      case LoanApplicationStatus.active:
        return 'Active loan';
      case LoanApplicationStatus.completed:
        return 'Fully repaid';
      case LoanApplicationStatus.defaulted:
        return 'Payment defaulted';
      case LoanApplicationStatus.cancelled:
        return 'Application cancelled';
      case LoanApplicationStatus.rejected:
        return 'Application rejected';
      case LoanApplicationStatus.rolledOver:
        return 'Rolled over to new loan';
    }
  }

  /// Whether this is a terminal state that cannot transition to other states
  bool get isTerminalState {
    return this == completed || 
           this == cancelled || 
           this == rejected ||
           this == rolledOver;
  }

  /// Whether the loan is currently active and requires payments
  bool get isActive => this == active;

  /// Whether the application can be modified
  bool get canBeModified => this == initial || this == pending;
}
