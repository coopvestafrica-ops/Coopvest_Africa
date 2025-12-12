import 'package:flutter/material.dart';

/// A navigation observer that tracks route changes in the app
class AppNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logRouteChange('PUSH', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logRouteChange('POP', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logRouteChange('REPLACE', newRoute, oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _logRouteChange('REMOVE', route, previousRoute);
  }

  void _logRouteChange(
      String action, Route<dynamic>? newRoute, Route<dynamic>? oldRoute) {
    final newRouteName = newRoute?.settings.name ?? 'unknown';
    final oldRouteName = oldRoute?.settings.name ?? 'unknown';
    debugPrint('Navigation $action: from $oldRouteName to $newRouteName');
  }
}
