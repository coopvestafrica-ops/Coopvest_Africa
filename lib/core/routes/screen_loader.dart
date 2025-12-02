import 'package:flutter/material.dart';

// This file uses deferred imports to lazy-load screens
// Deferred imports mean screens are only loaded when accessed via AppRouteGenerator
// This reduces initial app startup time significantly

// Import screens as deferred
// ignore: uri_does_not_exist
import '../../features/splash/presentation/screens/splash_screen.dart'
    deferred as splash;

// ignore: uri_does_not_exist
import '../../features/onboarding/presentation/screens/onboarding_screen.dart'
    deferred as onboarding;

// ignore: uri_does_not_exist
import '../../features/auth/presentation/screens/login_screen.dart'
    deferred as login;

// ignore: uri_does_not_exist
import '../../features/auth/presentation/screens/signup_screen.dart'
    deferred as signup;

// ignore: uri_does_not_exist
import '../../features/dashboard/presentation/screens/dashboard_screen.dart'
    deferred as dashboard;

// ignore: uri_does_not_exist
import '../../features/contributions/presentation/screens/contribution_screen.dart'
    deferred as contribution;

// ignore: uri_does_not_exist
import '../../features/loans/presentation/screens/loan_application_screen.dart'
    deferred as loan;

// ignore: uri_does_not_exist
import '../../features/savings/presentation/screens/savings_screen.dart'
    deferred as savings;

// ignore: uri_does_not_exist
import '../../features/wallet/presentation/screens/wallet_screen.dart'
    deferred as wallet;

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
}
