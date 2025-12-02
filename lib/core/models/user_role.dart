enum UserRole {
  admin,
  loanStaff,
  financeOfficer,
  complianceOfficer,
  member;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.loanStaff:
        return 'Loan Officer';
      case UserRole.financeOfficer:
        return 'Finance Officer';
      case UserRole.complianceOfficer:
        return 'Compliance Officer';
      case UserRole.member:
        return 'Member';
    }
  }
}
