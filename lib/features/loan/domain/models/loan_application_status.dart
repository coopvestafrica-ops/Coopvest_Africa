enum LoanApplicationStatus {
  initial,
  submitting,
  pendingReview,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case LoanApplicationStatus.initial:
        return 'Initial';
      case LoanApplicationStatus.submitting:
        return 'Submitting';
      case LoanApplicationStatus.pendingReview:
        return 'Pending Review';
      case LoanApplicationStatus.approved:
        return 'Approved';
      case LoanApplicationStatus.rejected:
        return 'Rejected';
    }
  }
}
