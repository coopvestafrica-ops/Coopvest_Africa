import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/device_info_service.dart';
import '../utils/connectivity_checker.dart';
import '../../features/dashboard/data/services/dashboard_service.dart';

/// Interface for disposable services
abstract class Disposable {
  Future<void> dispose();
}

/// Custom error for service lookup failures
class ServiceNotFoundError implements Exception {
  final Type serviceType;
  
  ServiceNotFoundError(this.serviceType);
  
  @override
  String toString() => 'Service of type ${serviceType.toString()} not found. '
      'Make sure initializeServices() was called.';
}

/// Custom error for service initialization failures
class ServiceInitializationError implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  ServiceInitializationError(this.message, {this.cause, this.stackTrace});

  @override
  String toString() => 'ServiceInitializationError: $message${cause != null ? '\nCause: $cause' : ''}';
}

/// Custom error for service disposal failures
class ServiceDisposalError implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  ServiceDisposalError(this.message, {this.cause, this.stackTrace});

  @override
  String toString() => 'ServiceDisposalError: $message${cause != null ? '\nCause: $cause' : ''}';
}

/// A service locator that manages singleton and lazy-loaded services
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  static ServiceLocator get instance => _instance;
  
  ServiceLocator._internal() {
    _log('Service locator created');
  }
  
  final Map<Type, Object> _singletons = {};
  final Map<Type, Function> _factories = {};
  bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;

  void _log(String message, {Object? error, StackTrace? stackTrace, String? name}) {
    final prefix = name != null ? '[$name] ' : '';
    debugPrint('$prefix$message');
    if (error != null) {
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace:\n$stackTrace');
      }
    }
  }

  void registerSingleton<T extends Object>(T instance) {
    _singletons[T] = instance;
    debugPrint('Registered singleton: ${T.toString()}');
  }

  void registerLazySingleton<T extends Object>(T Function() factory) {
    _factories[T] = factory;
    debugPrint('Registered factory: ${T.toString()}');
  }

  T get<T extends Object>() {
    final instance = _singletons[T];
    if (instance != null) return instance as T;

    final factory = _factories[T];
    if (factory != null) {
      try {
        final instance = (factory as T Function())();
        _singletons[T] = instance; // Cache the instance
        return instance;
      } catch (e, stack) {
        debugPrint('Error creating instance of ${T.toString()}: $e\n$stack');
        rethrow;
      }
    }

    throw ServiceNotFoundError(T);
  }

  bool isRegistered<T extends Object>() {
    return _singletons.containsKey(T) || _factories.containsKey(T);
  }

  Future<void> initializeServices() async {
    if (_isInitialized) {
      _log('Services already initialized');
      return;
    }

    try {
      _log('Initializing services...', name: runtimeType.toString());

      // Initialize SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      registerSingleton<SharedPreferences>(prefs);

      // Initialize core services
      final connectivityChecker = ConnectivityChecker();
      registerSingleton<ConnectivityChecker>(connectivityChecker);

      // Initialize device and security services
      try {
        // Initialize BiometricService
        final biometricService = BiometricService.instance;
        await biometricService.initialize();
        registerSingleton<BiometricService>(biometricService);

        // Initialize DeviceInfoService
        final deviceInfoService = DeviceInfoService.instance;
        await deviceInfoService.initialize();
        registerSingleton<DeviceInfoService>(deviceInfoService);
      } catch (e, stack) {
        _log(
          'Warning: Some device services failed to initialize',
          error: e,
          stackTrace: stack,
          name: runtimeType.toString()
        );
      }

      // Initialize auth service
      try {
        await AuthService.initialize();
        final authService = AuthService.instance;
        registerSingleton<AuthService>(authService);
      } catch (e, stack) {
        _log(
          'Error initializing auth service',
          error: e,
          stackTrace: stack,
          name: runtimeType.toString()
        );
        rethrow;
      }

      // Initialize API service with dependencies
      final apiService = ApiService.instance;
      registerSingleton<ApiService>(apiService);

      // Register feature services
      registerLazySingleton<DashboardService>(() {
        return DashboardService(get<ApiService>());
      });

      _isInitialized = true;
      _log('Services initialized successfully', name: runtimeType.toString());
    } catch (e, stack) {
      final error = ServiceInitializationError(
        'Failed to initialize services',
        cause: e,
        stackTrace: stack
      );
      _log(
        error.toString(),
        error: e,
        stackTrace: stack,
        name: runtimeType.toString()
      );
      throw error;
    }
  }

  Future<void> disposeServices() async {
    if (!_isInitialized) {
      _log('Services not initialized', name: runtimeType.toString());
      return;
    }

    try {
      _log('Disposing services...', name: runtimeType.toString());

      // Dispose services in reverse dependency order
      final servicesToDispose = [
        DashboardService,
        ApiService,
        AuthService,
        BiometricService,
        DeviceInfoService,
        ConnectivityChecker,
      ];

      for (final type in servicesToDispose) {
        try {
          final instance = _singletons[type];
          if (instance == null) continue;

          if (instance is Disposable) {
            await instance.dispose();
            _log('Disposed service: ${type.toString()}', name: runtimeType.toString());
          }
        } catch (e, stack) {
          _log(
            'Error disposing service ${type.toString()}',
            error: e,
            stackTrace: stack,
            name: runtimeType.toString()
          );
        }
      }

      _singletons.clear();
      _factories.clear();
      _isInitialized = false;
      
      _log('All services disposed', name: runtimeType.toString());
    } catch (e, stack) {
      final error = ServiceDisposalError(
        'Failed to dispose services',
        cause: e,
        stackTrace: stack
      );
      _log(
        error.toString(),
        error: e,
        stackTrace: stack,
        name: runtimeType.toString()
      );
      throw error;
    }
  }

  void reset() {
    _singletons.clear();
    _factories.clear();
    _isInitialized = false;
    debugPrint('Service locator reset');
  }
}
