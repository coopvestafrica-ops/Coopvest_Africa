import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/permission_provider.dart';

/// A widget that conditionally renders its child based on user permissions.
/// Shows a loading indicator while checking permissions and an error widget
/// or alternative widget when permissions are not met.
class PermissionGate extends StatelessWidget {
  /// The permission or list of permissions required to view the child widget
  final dynamic requiredPermissions;

  /// The widget to show when the user has the required permissions
  final Widget child;

  /// Whether all permissions are required (true) or any permission is sufficient (false)
  final bool requireAll;

  /// Widget to show when permissions are denied
  /// If not provided, shows a default "Access Denied" message
  final Widget? fallbackWidget;

  /// Widget to show while loading permissions
  /// If not provided, shows a default loading indicator
  final Widget? loadingWidget;

  /// Whether to show an error message when permissions are denied
  /// If false, shows the fallbackWidget silently
  final bool showError;

  /// Creates a permission gate that checks for user permissions before rendering its child.
  ///
  /// [requiredPermissions] can be either a single String permission or a List of String permissions.
  /// [child] is the widget to show when permissions are granted.
  /// [requireAll] determines if all permissions are needed (true) or any permission is sufficient (false).
  /// [fallbackWidget] is shown when permissions are denied.
  /// [loadingWidget] is shown while checking permissions.
  /// [showError] determines if an error message should be shown when access is denied.
  const PermissionGate({
    super.key,
    required this.requiredPermissions,
    required this.child,
    this.requireAll = true,
    this.fallbackWidget,
    this.loadingWidget,
    this.showError = true,
  });

  @override
  Widget build(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context);

    // If permissions are still loading, show loading widget
    if (permissionProvider.isLoading) {
      return loadingWidget ??
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
    }

    // If there was an error loading permissions, show error state
    if (permissionProvider.error != null) {
      return _buildErrorWidget(context, permissionProvider.error!);
    }

    return FutureBuilder<bool>(
      future: _checkPermissions(permissionProvider),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(context, snapshot.error.toString());
        }

        final hasPermission = snapshot.data ?? false;
        if (!hasPermission) {
          return _buildFallbackWidget(context);
        }

        return child;
      },
    );
  }

  Future<bool> _checkPermissions(PermissionProvider provider) async {
    if (requiredPermissions is String) {
      return provider.hasPermission(requiredPermissions as String);
    }

    if (requiredPermissions is List<String>) {
      return requireAll
          ? provider.hasAllPermissions(requiredPermissions as List<String>)
          : provider.hasAnyPermission(requiredPermissions as List<String>);
    }

    throw ArgumentError(
      'requiredPermissions must be either String or List<String>',
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error checking permissions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackWidget(BuildContext context) {
    if (fallbackWidget != null) {
      return fallbackWidget!;
    }

    if (!showError) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Access Denied',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'You do not have the required permissions to view this content.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
