import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth/auth_service.dart';
import '../core/utils/logger.dart';

/// App router configuration with protected routes
class AppRouter {
  final AuthService authService;

  AppRouter({required this.authService});

  /// Get GoRouter instance
  GoRouter getRouter() {
    return GoRouter(
      debugLogDiagnostics: true,
      redirect: _handleRedirect,
      refreshListenable: authService,
      routes: [
        // Splash screen
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Auth routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // Protected routes
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
  }

  /// Handle navigation redirects based on auth state
  Future<String?> _handleRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    try {
      final isAuthenticated = authService.isAuthenticated;
      final isGoingToSplash = state.matchedLocation == '/';
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSignUp = state.matchedLocation == '/signup';
      final isGoingToForgotPassword =
          state.matchedLocation == '/forgot-password';

      AppLogger.debug(
        'Redirect check - isAuthenticated: $isAuthenticated, location: ${state.matchedLocation}',
      );

      // If going to splash, check auth status
      if (isGoingToSplash) {
        // Wait a moment for initialization
        await Future.delayed(const Duration(milliseconds: 500));

        if (isAuthenticated) {
          return '/home';
        } else {
          return '/login';
        }
      }

      // If authenticated, redirect away from auth screens
      if (isAuthenticated) {
        if (isGoingToLogin || isGoingToSignUp || isGoingToForgotPassword) {
          return '/home';
        }
      } else {
        // If not authenticated, redirect away from protected screens
        if (!isGoingToLogin &&
            !isGoingToSignUp &&
            !isGoingToForgotPassword &&
            !isGoingToSplash) {
          return '/login';
        }
      }

      return null;
    } catch (e) {
      AppLogger.error('Error in redirect logic', e);
      return '/login';
    }
  }
}

// Placeholder screens - replace with actual implementations
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Login Screen'),
      ),
    );
  }
}

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Sign Up Screen'),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Forgot Password Screen'),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Home Screen'),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Profile Screen'),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Settings Screen'),
      ),
    );
  }
}
