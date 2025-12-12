import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/connectivity_checker.dart';

/// Provides app-wide connectivity state management
class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityChecker _connectivityChecker;
  late StreamSubscription<ConnectivityState> _subscription;
  ConnectivityState _state = ConnectivityState(
    hasConnection: true,
    type: ConnectivityResult.none,
    timestamp: DateTime.now(),
  );
  bool _checking = false;

  ConnectivityProvider(this._connectivityChecker) {
    _init();
  }

  /// Whether the device currently has an internet connection
  bool get hasConnection => _state.hasConnection;

  /// The current type of connection (wifi, mobile, etc.)
  ConnectivityResult get connectionType => _state.type;

  /// Whether we're currently checking connectivity
  bool get isChecking => _checking;

  /// Whether the current connection is via WiFi
  bool get isWifi => _state.isWifi;

  /// Whether the current connection is via mobile data
  bool get isMobile => _state.isMobile;

  /// Whether there was an error checking connectivity
  bool get hasError => _state.hasError;

  /// The error message if there was an error checking connectivity
  String? get error => _state.error;

  /// The current connectivity state
  ConnectivityState get state => _state;

  void _init() async {
    // Get initial state
    _checking = true;
    notifyListeners();

    try {
      _state = await _connectivityChecker.checkConnectivity();
    } finally {
      _checking = false;
      notifyListeners();
    }

    // Listen for changes
    _subscription = _connectivityChecker.onConnectivityChanged.listen((state) {
      _state = state;
      notifyListeners();
    });
  }

  /// Manually check current connectivity status
  Future<void> checkConnectivity() async {
    if (_checking) return;

    _checking = true;
    notifyListeners();

    try {
      _state = await _connectivityChecker.checkConnectivity();
    } finally {
      _checking = false;
      notifyListeners();
    }
  }

  /// Test if a specific host is reachable
  Future<bool> canReachHost(String host) => _connectivityChecker.canReachHost(host);

  @override
  void dispose() {
    _subscription.cancel();
    _connectivityChecker.dispose();
    super.dispose();
  }
}
