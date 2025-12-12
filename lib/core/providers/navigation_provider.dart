import 'package:flutter/material.dart';

/// Navigation provider for managing navigation state
/// This is a context-friendly alternative to global navigator keys
/// 
/// Usage:
/// ```dart
/// // In widget/screen
/// context.read<NavigationProvider>().navigateTo('/dashboard');
/// 
/// // Or with context
/// Navigator.of(context).pushNamed('/dashboard'); // PREFERRED
/// ```
class NavigationProvider extends ChangeNotifier {
  // Track navigation history
  final List<String> _navigationHistory = [];

  // Track current route
  String _currentRoute = '/';

  // Getters
  String get currentRoute => _currentRoute;

  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);

  bool get canGoBack => _navigationHistory.length > 1;

  /// Record navigation event
  void recordNavigation(String routeName) {
    _currentRoute = routeName;
    _navigationHistory.add(routeName);
    notifyListeners();
  }

  /// Navigate to a route by name
  /// Note: This only updates the provider state
  /// Actual navigation should be done via Navigator
  void navigateTo(String routeName) {
    recordNavigation(routeName);
  }

  /// Navigate back to previous route
  void goBack() {
    if (canGoBack) {
      _navigationHistory.removeLast();
      _currentRoute = _navigationHistory.last;
      notifyListeners();
    }
  }

  /// Clear navigation history
  void clearHistory() {
    _navigationHistory.clear();
    _currentRoute = '/';
    notifyListeners();
  }

  /// Get navigation breadcrumb
  String getNavigationBreadcrumb() {
    return _navigationHistory.join(' → ');
  }

  /// Check if user has visited a route
  bool hasVisited(String routeName) {
    return _navigationHistory.contains(routeName);
  }
}
