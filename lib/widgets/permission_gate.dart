import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/permission_provider.dart';

enum PermissionCheckMode {
  /// All permissions must be granted
  all,

  /// At least one permission must be granted
  any
}

class PermissionGate extends StatefulWidget {
  /// The permission(s) required to access the child widget
  final List<String> permissions;

  /// The widget to show if permissions are granted
  final Widget child;

  /// The widget to show if permissions are denied
  final Widget? fallback;

  /// Widget to show while checking permissions
  final Widget? loadingWidget;

  /// Whether all permissions are required or just any one of them
  final PermissionCheckMode mode;

  /// Whether to show an error indicator if permission check fails
  final bool showError;

  PermissionGate({
    super.key,
    required String permission,
    required this.child,
    this.fallback,
    this.loadingWidget,
    this.mode = PermissionCheckMode.all,
    this.showError = false,
  }) : permissions = [permission];

  PermissionGate.multiple({
    super.key,
    required this.permissions,
    required this.child,
    this.fallback,
    this.loadingWidget,
    this.mode = PermissionCheckMode.all,
    this.showError = false,
  }) {
    if (permissions.isEmpty) {
      throw ArgumentError('At least one permission must be specified');
    }
  }

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool? _hasPermission;
  String? _error;

  // Cache permission results
  final Map<String, bool> _permissionCache = {};

  // Store permission provider reference
  late final PermissionProvider _permissionProvider;

  @override
  void initState() {
    super.initState();
    _permissionProvider =
        Provider.of<PermissionProvider>(context, listen: false);
    _checkPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-check permissions if provider state changes
    Provider.of<PermissionProvider>(context);
    _checkPermissions();
  }

  @override
  void didUpdateWidget(PermissionGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-check if permissions changed
    if (!_arePermissionsEqual(oldWidget.permissions, widget.permissions) ||
        oldWidget.mode != widget.mode) {
      _checkPermissions();
    }
  }

  bool _arePermissionsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    return a.every((perm) => b.contains(perm));
  }

  Future<void> _checkPermissions() async {
    if (!mounted) return;

    setState(() {
      _hasPermission = null;
      _error = null;
      _permissionCache.clear(); // Clear cache on each check
    });

    try {
      // Check permissions based on mode
      if (widget.mode == PermissionCheckMode.all) {
        // All permissions must be granted
        final List<bool> results = await Future.wait(
          widget.permissions.map((permission) async {
            return _permissionProvider.hasPermission(permission);
          }),
        );

        if (!mounted) return;
        setState(() {
          _hasPermission = results.every((result) => result);
        });
      } else {
        // Any permission is sufficient
        final List<bool> results = await Future.wait(
          widget.permissions.map((permission) async =>
              _permissionProvider.hasPermission(permission)),
        );

        if (!mounted) return;
        setState(() {
          _hasPermission = results.any((result) => result);
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to check permissions: $e';
        _hasPermission = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: ExcludeSemantics(
        excluding: false,
        child: Builder(builder: (context) {
          // Show loading widget while checking permissions
          if (_hasPermission == null) {
            return Semantics(
              label: 'Checking permissions...',
              value: 'Please wait while we verify your access.',
              child: widget.loadingWidget ??
                  const Center(child: CircularProgressIndicator()),
            );
          }

          // Show error if permission check failed
          if (_error != null && widget.showError) {
            return Semantics(
              label: 'Permission Error',
              value: _error,
              button: true,
              onTapHint: 'Retry checking permissions',
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.red,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _checkPermissions,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show child or fallback based on permission result
          if (_hasPermission == true) {
            return Semantics(
              enabled: true,
              child: widget.child,
            );
          } else {
            return Semantics(
              enabled: false,
              label: 'Access Denied',
              value: 'You do not have permission to view this content',
              child: widget.fallback ?? const SizedBox.shrink(),
            );
          }
        }),
      ),
    );
  }
}
