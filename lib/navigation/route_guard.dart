import 'package:flutter/material.dart';
import '../services/auth/auth_service.dart';
import '../core/utils/logger.dart';

/// Route guard for protecting screens based on authentication state
class RouteGuard {
  final AuthService authService;

  RouteGuard({required this.authService});

  /// Check if user can access protected route
  Future<bool> canActivate() async {
    try {
      AppLogger.debug('Checking route access');
      final isAuthenticated = await authService.checkAuthStatus();
      AppLogger.debug('Route access check result: $isAuthenticated');
      return isAuthenticated;
    } catch (e) {
      AppLogger.error('Error checking route access', e);
      return false;
    }
  }

  /// Check if user can access public route (not authenticated)
  Future<bool> canActivatePublic() async {
    try {
      AppLogger.debug('Checking public route access');
      final isAuthenticated = authService.isAuthenticated;
      AppLogger.debug('Public route access check result: ${!isAuthenticated}');
      return !isAuthenticated;
    } catch (e) {
      AppLogger.error('Error checking public route access', e);
      return true;
    }
  }

  /// Check if user is admin
  Future<bool> isAdmin() async {
    try {
      final user = authService.currentUser;
      // Add your admin check logic here
      return user != null; // Placeholder
    } catch (e) {
      AppLogger.error('Error checking admin status', e);
      return false;
    }
  }
}

/// Widget for protecting routes
class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final AuthService authService;
  final VoidCallback? onUnauthorized;

  const ProtectedRoute({
    Key? key,
    required this.child,
    this.fallback,
    required this.authService,
    this.onUnauthorized,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: RouteGuard(authService: authService).canActivate(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          AppLogger.error('Error in ProtectedRoute', snapshot.error);
          return const Scaffold(
            body: Center(
              child: Text('An error occurred'),
            ),
          );
        }

        if (snapshot.data == true) {
          return child;
        } else {
          onUnauthorized?.call();
          return fallback ??
              const Scaffold(
                body: Center(
                  child: Text('Unauthorized'),
                ),
              );
        }
      },
    );
  }
}
