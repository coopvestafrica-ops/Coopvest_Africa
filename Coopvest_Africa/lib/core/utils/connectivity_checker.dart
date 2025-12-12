import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:meta/meta.dart';

/// A class that provides detailed connectivity checking functionality.
/// 
/// Features:
/// - Checks network connectivity status
/// - Verifies actual internet connection
/// - Caches connectivity state
/// - Provides detailed connection type information
/// - Handles timeouts and retries
class ConnectivityChecker {
  static const Duration _timeout = Duration(seconds: 5);
  static const Duration _cacheValidity = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const List<String> _testUrls = [
    'https://www.google.com',
    'https://www.cloudflare.com',
    '8.8.8.8', // Google DNS
  ];

  final Connectivity _connectivity;
  DateTime? _lastCheckTime;
  bool? _lastKnownState;
  ConnectivityResult? _lastKnownType;
  final _connectionChangedController = StreamController<ConnectivityState>.broadcast();

  /// Gets whether there is currently an active internet connection.
  /// This checks both network connectivity and actual internet access.
  Future<bool> get hasConnection async {
    final state = await checkConnectivity();
    return state.hasConnection;
  }

  ConnectivityChecker({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Gets the current connectivity state including connection type and strength.
  /// 
  /// Returns a [ConnectivityState] object containing detailed connection information.
  Future<ConnectivityState> checkConnectivity() async {
    // Check cache first
    if (_canUseCache) {
      return ConnectivityState(
        hasConnection: _lastKnownState!,
        type: _lastKnownType!,
        timestamp: _lastCheckTime!,
      );
    }

    try {
      // Check basic connectivity first
      final connectivityResults = await _connectivity.checkConnectivity();
      final connectivityResult = _getEffectiveConnectivityResult(connectivityResults);
      
      if (connectivityResult == ConnectivityResult.none) {
        _updateState(false, connectivityResult);
        return ConnectivityState(
          hasConnection: false,
          type: connectivityResult,
          timestamp: DateTime.now(),
        );
      }

      // Verify actual internet connectivity
      final hasInternet = await _verifyInternetConnectivity();
      _updateState(hasInternet, connectivityResult);

      final state = ConnectivityState(
        hasConnection: hasInternet,
        type: connectivityResult,
        timestamp: DateTime.now(),
      );

      // Notify listeners if state changed
      if (_shouldNotifyListeners(state)) {
        _connectionChangedController.add(state);
      }

      return state;
    } catch (e) {
      // On error, return cached state if available, otherwise assume no connection
      if (_lastKnownState != null) {
        return ConnectivityState(
          hasConnection: _lastKnownState!,
          type: _lastKnownType ?? ConnectivityResult.none,
          timestamp: _lastCheckTime ?? DateTime.now(),
          error: e.toString(),
        );
      }
      
      return ConnectivityState(
        hasConnection: false,
        type: ConnectivityResult.none,
        timestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Stream of connectivity changes.
  /// 
  /// Emits a new [ConnectivityState] whenever the connectivity status changes.
  Stream<ConnectivityState> get onConnectivityChanged {
    // Listen to platform connectivity changes
    _connectivity.onConnectivityChanged.listen((results) async {
      final result = _getEffectiveConnectivityResult(results);
      if (result == ConnectivityResult.none) {
        _connectionChangedController.add(
          ConnectivityState(
            hasConnection: false,
            type: result,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        // Verify actual internet connectivity
        final state = await checkConnectivity();
        _connectionChangedController.add(state);
      }
    });

    return _connectionChangedController.stream;
  }

  /// Tests if a specific host is reachable.
  /// 
  /// Returns true if the host can be reached, false otherwise.
  Future<bool> canReachHost(String host) async {
    try {
      final result = await InternetAddress.lookup(host)
          .timeout(_timeout);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }

  /// Verifies actual internet connectivity by testing multiple endpoints.
  Future<bool> _verifyInternetConnectivity() async {
    for (var i = 0; i < _maxRetries; i++) {
      for (final url in _testUrls) {
        try {
          if (await canReachHost(url)) {
            return true;
          }
        } catch (_) {
          continue;
        }
      }
      // Small delay before retry
      if (i < _maxRetries - 1) {
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
    return false;
  }

  /// Updates the cached connectivity state
  void _updateState(bool hasConnection, ConnectivityResult type) {
    _lastKnownState = hasConnection;
    _lastKnownType = type;
    _lastCheckTime = DateTime.now();
  }

  /// Checks if the cached state is still valid
  bool get _canUseCache {
    if (_lastCheckTime == null || _lastKnownState == null) return false;
    return DateTime.now().difference(_lastCheckTime!) < _cacheValidity;
  }

  /// Determines if listeners should be notified of state change
  bool _shouldNotifyListeners(ConnectivityState newState) {
    if (_lastKnownState == null || _lastKnownType == null) return true;
    return _lastKnownState != newState.hasConnection || 
           _lastKnownType != newState.type;
  }

  /// Gets the most relevant connectivity result from a list of results
  ConnectivityResult _getEffectiveConnectivityResult(List<ConnectivityResult> results) {
    if (results.isEmpty) return ConnectivityResult.none;
    
    // Prioritize connections in order: ethernet > wifi > mobile > vpn > bluetooth > other > none
    if (results.contains(ConnectivityResult.ethernet)) return ConnectivityResult.ethernet;
    if (results.contains(ConnectivityResult.wifi)) return ConnectivityResult.wifi;
    if (results.contains(ConnectivityResult.mobile)) return ConnectivityResult.mobile;
    if (results.contains(ConnectivityResult.vpn)) return ConnectivityResult.vpn;
    if (results.contains(ConnectivityResult.bluetooth)) return ConnectivityResult.bluetooth;
    if (results.contains(ConnectivityResult.other)) return ConnectivityResult.other;
    return ConnectivityResult.none;
  }

  /// Disposes of resources
  void dispose() {
    _connectionChangedController.close();
  }
}

/// Represents the current state of connectivity.
@immutable
class ConnectivityState {
  final bool hasConnection;
  final ConnectivityResult type;
  final DateTime timestamp;
  final String? error;

  const ConnectivityState({
    required this.hasConnection,
    required this.type,
    required this.timestamp,
    this.error,
  });

  /// Whether this is a mobile connection (cellular data)
  bool get isMobile => type == ConnectivityResult.mobile;

  /// Whether this is a WiFi connection
  bool get isWifi => type == ConnectivityResult.wifi;

  /// Whether this is an ethernet connection
  bool get isEthernet => type == ConnectivityResult.ethernet;

  /// Whether this is a VPN connection
  bool get isVpn => type == ConnectivityResult.vpn;

  /// Whether this state represents no connectivity
  bool get isDisconnected => type == ConnectivityResult.none;

  /// Whether this state has an error
  bool get hasError => error != null;

  /// The age of this state
  Duration get age => DateTime.now().difference(timestamp);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectivityState &&
          runtimeType == other.runtimeType &&
          hasConnection == other.hasConnection &&
          type == other.type;

  @override
  int get hashCode => hasConnection.hashCode ^ type.hashCode;

  @override
  String toString() => 'ConnectivityState('
      'hasConnection: $hasConnection, '
      'type: $type, '
      'timestamp: $timestamp'
      '${error != null ? ', error: $error' : ''}'
      ')';
}
