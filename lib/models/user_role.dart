enum UserRole {
  admin,
  loanStaff,
  financeOfficer,
  complianceOfficer,
  member
}

class RolePermissions {
  static const Map<UserRole, List<String>> permissions = {
    UserRole.admin: [
      'manage_users',
      'manage_roles',
      'view_audit_logs',
      'grant_permissions',
      'revoke_permissions',
      'view_admin_dashboard',
      'manage_system_settings'
    ],
    UserRole.loanStaff: [
      'view_loan_requests',
      'validate_guarantors',
      'approve_loans',
      'view_loan_history',
      'generate_loan_reports'
    ],
    UserRole.financeOfficer: [
      'view_wallet_transactions',
      'process_disbursements',
      'view_contributions',
      'generate_financial_reports',
      'manage_payment_settings'
    ],
    UserRole.complianceOfficer: [
      'view_audit_trails',
      'monitor_transactions',
      'view_compliance_reports',
      'flag_suspicious_activity',
      'view_kyc_documents'
    ],
    UserRole.member: [
      'view_own_profile',
      'apply_for_loan',
      'guarantee_loan',
      'view_own_transactions',
      'make_contributions'
    ]
  };
}
