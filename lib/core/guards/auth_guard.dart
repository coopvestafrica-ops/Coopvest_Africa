import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_screen.dart';
import '../../signup_screen.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final bool maintainState;

  const AuthGuard({
    super.key,
    required this.child,
    this.maintainState = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Show loading screen while checking auth
        if (auth.isAuthenticating || auth.status == AuthStatus.initial) {
          return const LoadingScreen();
        }

        // Redirect to signup if not authenticated
        if (!auth.isAuthenticated) {
          return const SignupScreen();
        }

        return maintainState ? child : RepaintBoundary(child: child);
      },
    );
  }
}
