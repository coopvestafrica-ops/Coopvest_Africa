import 'package:flutter/material.dart';

// This file uses deferred imports to lazy-load screens
// Deferred imports mean screens are only loaded when accessed via AppRouteGenerator
// This reduces initial app startup time significantly

// Import screens as deferred - FIXED PATHS
import '../../splash_screen.dart' deferred as splash;
import '../../onboarding_screen.dart' deferred as onboarding;
import '../../login_screen.dart' deferred as login;
import '../../signup_screen.dart' deferred as signup;
import '../../features/dashboard/presentation/screens/dashboard_screen.dart' deferred as dashboard;
import '../../contribution_screen.dart' deferred as contribution;
import '../../loan_application_screen.dart' deferred as loan;
import '../../savings_screen.dart' deferred as savings;
import '../../wallet_screen.dart' deferred as wallet;

// Import orphaned screens
import '../../guarantor_loan_screen.dart' deferred as guarantor_loan;
import '../../guarantor_scan_screen.dart' deferred as guarantor_scan;
import '../../loan_qr_confirmation_screen.dart' deferred as loan_qr;
import '../../my_guarantees_screen.dart' deferred as my_guarantees;
import '../../referral_screen.dart' deferred as referral;
import '../../features/loan/presentation/screens/loan_status_screen.dart' deferred as loan_status;
import '../../features/loan/presentation/screens/rollover_approval_screen.dart' deferred as rollover;
import '../../features/tickets/presentation/screens/ticket_list_screen.dart' deferred as ticket_list;
import '../../features/tickets/presentation/screens/create_ticket_screen.dart' deferred as create_ticket;
import '../../features/tickets/presentation/screens/ticket_detail_screen.dart' deferred as ticket_detail;
import '../../screens/salary_deduction_consent_screen.dart' deferred as salary_consent;

/// Screen loader class that handles lazy loading of all app screens
///
/// Benefits of this approach:
/// - ✅ Reduced initial app load time (screens only loaded when accessed)
/// - ✅ Better memory usage (screens unloaded after navigation)
/// - ✅ Improved code splitting for app bundle optimization
/// - ✅ Progressive loading experience
///
/// Usage:
/// ```dart
/// final screen = await ScreenLoader.loadSplashScreen();
/// final screen = await ScreenLoader.loadDashboard();
/// ```
class ScreenLoader {
  /// Loads and returns the splash screen
  static Future<Widget> loadSplashScreen() async {
    await splash.loadLibrary();
    return splash.SplashScreen();
  }

  /// Loads and returns the onboarding screen
  static Future<Widget> loadOnboardingScreen() async {
    await onboarding.loadLibrary();
    return onboarding.OnboardingScreen();
  }

  /// Loads and returns the login screen
  static Future<Widget> loadLoginScreen() async {
    await login.loadLibrary();
    return login.LoginScreen();
  }

  /// Loads and returns the signup screen
  static Future<Widget> loadSignupScreen() async {
    await signup.loadLibrary();
    return signup.SignupScreen();
  }

  /// Loads and returns the dashboard screen
  static Future<Widget> loadDashboardScreen() async {
    await dashboard.loadLibrary();
    return dashboard.DashboardScreen();
  }

  /// Loads and returns the contribution screen
  static Future<Widget> loadContributionScreen({required String userId}) async {
    await contribution.loadLibrary();
    return contribution.ContributionScreen(userId: userId);
  }

  /// Loads and returns the loan application screen
  static Future<Widget> loadLoanApplicationScreen({required String userId}) async {
    await loan.loadLibrary();
    return loan.LoanApplicationScreen(userId: userId);
  }

  /// Loads and returns the savings screen
  static Future<Widget> loadSavingsScreen({required String userId}) async {
    await savings.loadLibrary();
    return savings.SavingsScreen(userId: userId);
  }

  /// Loads and returns the wallet screen
  static Future<Widget> loadWalletScreen({required String userId}) async {
    await wallet.loadLibrary();
    return wallet.WalletScreen(userId: userId);
  }

  // NEW LOADER METHODS FOR ORPHANED SCREENS

  /// Loads and returns the guarantor loan screen
  static Future<Widget> loadGuarantorLoanScreen() async {
    await guarantor_loan.loadLibrary();
    return guarantor_loan.GuarantorLoanScreen();
  }

  /// Loads and returns the guarantor scan screen
  static Future<Widget> loadGuarantorScanScreen() async {
    await guarantor_scan.loadLibrary();
    return guarantor_scan.GuarantorScanScreen();
  }

  /// Loads and returns the loan QR confirmation screen
  static Future<Widget> loadLoanQrConfirmationScreen({required String loanId}) async {
    await loan_qr.loadLibrary();
    return loan_qr.LoanQrConfirmationScreen(loanId: loanId);
  }

  /// Loads and returns the my guarantees screen
  static Future<Widget> loadMyGuaranteesScreen({required String userId}) async {
    await my_guarantees.loadLibrary();
    return my_guarantees.MyGuaranteesScreen();
  }

  /// Loads and returns the referral screen
  static Future<Widget> loadReferralScreen({required String userId}) async {
    await referral.loadLibrary();
    return referral.ReferralScreen(referralCode: userId);
  }

  /// Loads and returns the loan status screen
  static Future<Widget> loadLoanStatusScreen({required String loanId}) async {
    await loan_status.loadLibrary();
    return loan_status.LoanStatusScreen(loanId: loanId);
  }

  /// Loads and returns the rollover approval screen
  static Future<Widget> loadRolloverApprovalScreen({required String loanId}) async {
    await rollover.loadLibrary();
    return rollover.RolloverApprovalScreen(loanId: loanId);
  }

  /// Loads and returns the ticket list screen
  static Future<Widget> loadTicketListScreen() async {
    await ticket_list.loadLibrary();
    return ticket_list.TicketListScreen();
  }

  /// Loads and returns the create ticket screen
  static Future<Widget> loadCreateTicketScreen() async {
    await create_ticket.loadLibrary();
    return create_ticket.CreateTicketScreen();
  }

  /// Loads and returns the ticket detail screen
  static Future<Widget> loadTicketDetailScreen({required String ticketId}) async {
    await ticket_detail.loadLibrary();
    return ticket_detail.TicketDetailScreen(ticketId: ticketId);
  }

  /// Loads and returns the salary deduction consent screen
  static Future<Widget> loadSalaryConsentScreen({Map<String, dynamic>? registrationData}) async {
    await salary_consent.loadLibrary();
    return salary_consent.SalaryDeductionConsentScreen(
      registrationData: registrationData ?? {},
    );
  }
}