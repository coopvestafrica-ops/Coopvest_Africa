import 'package:flutter/material.dart';

/// Navigation service for managing app-wide navigation without global keys
/// 
/// This replaces the anti-pattern of using global navigator keys
/// Provides a clean, testable, and context-aware navigation interface
/// 
/// Usage:
/// ```dart
/// NavigationService.instance.pushNamed('/dashboard');
/// NavigationService.instance.pop();
/// ```
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();

  factory NavigationService() {
    return _instance;
  }

  NavigationService._internal();

  static NavigationService get instance => _instance;

  /// Global navigator key - only used internally
  /// Not exposed publicly to discourage anti-pattern usage
  late GlobalKey<NavigatorState> _navigatorKey;

  /// Get the navigator key for MaterialApp configuration
  /// This is the only place that should directly use the key
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  /// Initialize the navigation service with a navigator key
  void initialize(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Get current navigation context
  /// Returns null if navigator is not available
  BuildContext? get context => _navigatorKey.currentContext;

  /// Get current navigator state
  /// Returns null if navigator is not available
  NavigatorState? get _currentState => _navigatorKey.currentState;

  /// Check if navigator is available
  bool get isNavigatorReady => _currentState != null;

  // ======================== NAVIGATION METHODS ========================

  /// Push a named route
  /// 
  /// Example: NavigationService.instance.pushNamed('/dashboard');
  Future<T?> pushNamed<T>(
    String routeName, {
    Object? arguments,
  }) {
    if (!isNavigatorReady) {
      debugPrint('⚠️ Navigator not ready for pushNamed($routeName)');
      return Future.value(null);
    }

    return _currentState!.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  /// Push a named route and remove all previous routes
  /// 
  /// Example: NavigationService.instance.pushNamedAndRemoveUntil('/login', (route) => false);
  Future<T?> pushNamedAndRemoveUntil<T>(
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    if (!isNavigatorReady) {
      debugPrint('⚠️ Navigator not ready for pushNamedAndRemoveUntil($routeName)');
      return Future.value(null);
    }

    return _currentState!.pushNamedAndRemoveUntil<T>(
      routeName,
      predicate,
      arguments: arguments,
    );
  }

  /// Replace current route with a new named route
  /// 
  /// Example: NavigationService.instance.pushReplacementNamed('/dashboard');
  Future<T?> pushReplacementNamed<T, TO>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    if (!isNavigatorReady) {
      debugPrint('⚠️ Navigator not ready for pushReplacementNamed($routeName)');
      return Future.value(null);
    }

    return _currentState!.pushReplacementNamed<T, TO>(
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  /// Pop current route
  /// 
  /// Example: NavigationService.instance.pop();
  void pop<T>([T? result]) {
    if (!isNavigatorReady) {
      debugPrint('⚠️ Navigator not ready for pop()');
      return;
    }

    _currentState!.pop<T>(result);
  }

  /// Pop multiple routes until predicate is true
  /// 
  /// Example: NavigationService.instance.popUntil((route) => route.isFirst);
  void popUntil(RoutePredicate predicate) {
    if (!isNavigatorReady) {
      debugPrint('⚠️ Navigator not ready for popUntil()');
      return;
    }

    _currentState!.popUntil(predicate);
  }

  /// Check if can pop (there are routes below current)
  bool canPop() {
    if (!isNavigatorReady) {
      return false;
    }

    return _currentState!.canPop();
  }

  /// Get the current route name
  String? get currentRouteName {
    if (!isNavigatorReady) {
      return null;
    }

    String? routeName;
    _currentState!.popUntil((route) {
      routeName = route.settings.name;
      return true;
    });

    return routeName;
  }

  // ======================== CONTEXT-AWARE METHODS ========================

  /// Push with context (preferred when available)
  /// 
  /// Usage in widget:
  /// ```dart
  /// void navigateToDashboard(BuildContext context) {
  ///   // Option 1: Use context directly (PREFERRED)
  ///   Navigator.of(context).pushNamed('/dashboard');
  ///
  ///   // Option 2: Use NavigationService as fallback
  ///   NavigationService.instance.pushNamed('/dashboard');
  /// }
  /// ```
  static void pushNamedWithContext(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.of(context).pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Recommended pattern: Always prefer context when available
  /// 
  /// ✅ GOOD: Use context in widgets/screens
  /// ```dart
  /// Navigator.of(context).pushNamed(AppRoutes.dashboard);
  /// ```
  ///
  /// ⚠️ FALLBACK: Use NavigationService when context unavailable
  /// ```dart
  /// if (context != null) {
  ///   Navigator.of(context).pushNamed(AppRoutes.dashboard);
  /// } else {
  ///   NavigationService.instance.pushNamed(AppRoutes.dashboard);
  /// }
  /// ```
  ///
  /// ❌ AVOID: Using global key for forced navigation
  /// ```dart
  /// navigatorKey.currentState!.pushNamed(...); // Don't do this!
  /// ```
}
