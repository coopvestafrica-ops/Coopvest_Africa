import 'dart:developer' as developer;
import 'package:flutter/material.dart';

// Screen imports will be added as screens are created

/// Route names used in the app
class AppRoutes {
  static const root = '/';
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const dashboard = '/dashboard';
  static const wallet = '/wallet';
  static const savings = '/savings';
  static const loan = '/loan';
  static const profile = '/profile';
  static const analytics = '/analytics';
  static const membershipTerminate = '/membership/terminate';
}

/// Handles route generation and navigation for the app
class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static final AppRouter _instance = AppRouter._internal();
  
  factory AppRouter() {
    return _instance;
  }
  
  AppRouter._internal();

  static Widget _buildPlaceholderScreen(String screenName) {
    return Scaffold(
      appBar: AppBar(
        title: Text(screenName),
      ),
      body: Center(
        child: Text('$screenName - To be implemented'),
      ),
    );
  }

  /// Generates routes based on route settings
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    try {
      developer.log(
        'Navigating to: ${settings.name}',
        name: 'AppRouter',
      );

      switch (settings.name) {
        case AppRoutes.root:
        case AppRoutes.splash:
          return MaterialPageRoute(
            builder: (_) => _buildPlaceholderScreen('Splash Screen'),
            settings: settings,
          );

        case AppRoutes.onboarding:
          return MaterialPageRoute(
            builder: (_) => _buildPlaceholderScreen('Onboarding Screen'),
            settings: settings,
          );

        case AppRoutes.login:
          return MaterialPageRoute(
            builder: (_) => _buildPlaceholderScreen('Login Screen'),
            settings: settings,
          );

        case AppRoutes.signup:
          return MaterialPageRoute(
            builder: (_) => _buildPlaceholderScreen('Signup Screen'),
            settings: settings,
          );

      case AppRoutes.dashboard: {
          final args = settings.arguments as Map<String, dynamic>?;
          validateRouteArgs(args, ['userId', 'firstName'], AppRoutes.dashboard);
          return MaterialPageRoute(
            builder: (_) => _buildPlaceholderScreen('Dashboard Screen'),
            settings: settings,
          );
        }

      case AppRoutes.wallet: {
          final args = settings.arguments as Map<String, dynamic>?;
          validateRouteArgs(args, ['userId'], AppRoutes.wallet);
          return MaterialPageRoute(
            builder: (_) => _buildPlaceholderScreen('Wallet Screen'),
            settings: settings,
          );
        }

      case AppRoutes.savings: {
          final args = settings.arguments as Map<String, dynamic>?;
          validateRouteArgs(args, ['userId'], AppRoutes.savings);
          return MaterialPageRoute(
            builder: (_) => _buildPlaceholderScreen('Savings Screen'),
            settings: settings,
          );
        }

      case AppRoutes.loan: {
          final args = settings.arguments as Map<String, dynamic>?;
          validateRouteArgs(args, ['userId'], AppRoutes.loan);
          return MaterialPageRoute(
            builder: (_) => _buildPlaceholderScreen('Loan Screen'),
            settings: settings,
          );
        }

      case AppRoutes.profile: {
          final args = settings.arguments as Map<String, dynamic>?;
          validateRouteArgs(args, ['userId', 'firstName'], AppRoutes.profile);
          return MaterialPageRoute(
            builder: (_) => _buildPlaceholderScreen('Profile Screen'),
            settings: settings,
          );
        }

      case AppRoutes.analytics: {
          final args = settings.arguments as Map<String, dynamic>?;
          validateRouteArgs(args, ['userId'], AppRoutes.analytics);
          return MaterialPageRoute(
            builder: (_) => _buildPlaceholderScreen('Analytics Dashboard'),
            settings: settings,
          );
        }

      case AppRoutes.membershipTerminate:
        return MaterialPageRoute(
          builder: (_) => _buildPlaceholderScreen('Membership Termination'),
          settings: settings,
        );

      default:
        developer.log(
          'No route found for ${settings.name}',
          name: 'AppRouter',
          error: 'Route not found',
        );
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('Not Found'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Page not found: ${settings.name}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    onPressed: () => Navigator.pop(navigatorKey.currentState!.context),
                  ),
                ],
              ),
            ),
          ),
          settings: settings,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error during navigation to ${settings.name}',
        name: 'AppRouter',
        error: e,
        stackTrace: stackTrace,
      );
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Error'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'An error occurred during navigation',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  onPressed: () => Navigator.pop(navigatorKey.currentState!.context),
                ),
              ],
            ),
          ),
        ),
        settings: settings,
      );
    }
  }

  /// Helper method to validate the required arguments for a route
  void validateRouteArgs(Map<String, dynamic>? args, List<String> requiredKeys, String routeName) {
    if (args == null) {
      throw ArgumentError('$routeName route requires arguments: ${requiredKeys.join(", ")}');
    }
    
    for (final key in requiredKeys) {
      if (!args.containsKey(key) || args[key] == null) {
        throw ArgumentError('$routeName route requires "$key" argument');
      }

      // Type validation for common argument types
      final value = args[key];
      if (key == 'userId' && value is! String) {
        throw ArgumentError('$routeName: userId must be a String');
      }
      if (key == 'firstName' && value is! String) {
        throw ArgumentError('$routeName: firstName must be a String');
      }
      if (key.contains('Id') && value is! String && value is! int) {
        throw ArgumentError('$routeName: $key must be a String or int');
      }
    }
  }
}
