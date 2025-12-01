import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';
import '../widgets/loading_screen.dart';
import 'screen_loader.dart';

// Route names constants
abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String contribution = '/contribution';
  static const String loan = '/loan';
  static const String savings = '/savings';
  static const String wallet = '/wallet';
}

/// Route generator with lazy loading
/// This avoids importing all screens upfront and allows code splitting
class AppRouteGenerator {
  static Route<dynamic> generateRoute(
    RouteSettings settings,
    AuthProvider authProvider,
  ) {
    // Get auth state
    final userId = authProvider.currentUser?.id ?? '';
    final isAuthenticated = authProvider.isAuthenticated;

    // Create the screen widget based on route
    final screenWidget = _getScreenWidget(
      routeName: settings.name ?? '/',
      isAuthenticated: isAuthenticated,
      userId: userId,
    );

    return MaterialPageRoute(
      builder: (_) => screenWidget,
      settings: settings,
      maintainState: true,
    );
  }

  /// Returns the appropriate screen based on route name
  /// Lazy loads screens using deferred imports to improve startup performance
  static Widget _getScreenWidget({
    required String routeName,
    required bool isAuthenticated,
    required String userId,
  }) {
    switch (routeName) {
      case AppRoutes.splash:
        return _LazyLoadScreen(
          screenBuilder: ScreenLoader.loadSplashScreen,
        );

      case AppRoutes.onboarding:
        return _LazyLoadScreen(
          screenBuilder: ScreenLoader.loadOnboardingScreen,
        );

      case AppRoutes.login:
        return _LazyLoadScreen(
          screenBuilder: ScreenLoader.loadLoginScreen,
        );

      case AppRoutes.signup:
        return _LazyLoadScreen(
          screenBuilder: ScreenLoader.loadSignupScreen,
        );

      case AppRoutes.dashboard:
        return _LazyLoadScreen(
          screenBuilder: ScreenLoader.loadDashboardScreen,
          requiresAuth: true,
          isAuthenticated: isAuthenticated,
        );

      case AppRoutes.contribution:
        return _LazyLoadScreen(
          screenBuilder: () =>
              ScreenLoader.loadContributionScreen(userId: userId),
          requiresAuth: true,
          isAuthenticated: isAuthenticated,
        );

      case AppRoutes.loan:
        return _LazyLoadScreen(
          screenBuilder: () =>
              ScreenLoader.loadLoanApplicationScreen(userId: userId),
          requiresAuth: true,
          isAuthenticated: isAuthenticated,
        );

      case AppRoutes.savings:
        return _LazyLoadScreen(
          screenBuilder: () => ScreenLoader.loadSavingsScreen(userId: userId),
          requiresAuth: true,
          isAuthenticated: isAuthenticated,
        );

      case AppRoutes.wallet:
        return _LazyLoadScreen(
          screenBuilder: () => ScreenLoader.loadWalletScreen(userId: userId),
          requiresAuth: true,
          isAuthenticated: isAuthenticated,
        );

      default:
        return _ErrorScreen(routeName: routeName);
    }
  }
}

/// Widget that handles lazy loading of screens
/// Shows loading indicator while screen is being prepared
class _LazyLoadScreen extends StatefulWidget {
  final Future<Widget> Function() screenBuilder;
  final bool requiresAuth;
  final bool isAuthenticated;

  const _LazyLoadScreen({
    required this.screenBuilder,
    this.requiresAuth = false,
    this.isAuthenticated = false,
  });

  @override
  State<_LazyLoadScreen> createState() => _LazyLoadScreenState();
}

class _LazyLoadScreenState extends State<_LazyLoadScreen> {
  late Future<Widget> _screenFuture;

  @override
  void initState() {
    super.initState();
    _screenFuture = _loadScreen();
  }

  Future<Widget> _loadScreen() async {
    // Check authentication if required
    if (widget.requiresAuth && !widget.isAuthenticated) {
      return const SignupRedirect();
    }

    // Load the deferred screen asynchronously
    return await widget.screenBuilder();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _screenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return _ErrorScreen(
                routeName: 'Unknown (Error: ${snapshot.error})');
          }
          return snapshot.data ?? const SizedBox();
        }

        // Show loading screen while lazy loading
        return const LoadingScreen();
      },
    );
  }
}

/// Redirect to signup screen when auth is required but user not authenticated
class SignupRedirect extends StatelessWidget {
  const SignupRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.signup,
        (route) => false,
      );
    });

    return const LoadingScreen();
  }
}

/// Error screen for unknown routes
class _ErrorScreen extends StatelessWidget {
  final String routeName;

  const _ErrorScreen({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Route not found: $routeName',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.dashboard,
                  (route) => false,
                ),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
