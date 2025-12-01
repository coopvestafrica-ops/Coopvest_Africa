import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'biometric_service.dart';
import 'device_info_service.dart';
import 'base_service.dart';
import 'service_error.dart';

/// A custom service locator for managing dependencies in the app.
/// Provides singleton and lazy singleton registration and resolution.
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  final Map<Type, _ServiceFactory> _factories = {};
  final Map<Type, Object> _singletons = {};
  final Map<Type, Completer<Object>> _asyncSingletons = {};

  ServiceLocator._internal();

  factory ServiceLocator() => _instance;

  /// Register a singleton instance that is created immediately.
  void registerSingleton<T extends Object>(T instance) {
    if (_factories.containsKey(T) || _singletons.containsKey(T)) {
      throw ServiceError.alreadyRegistered(T);
    }
    _singletons[T] = instance;
  }

  /// Register a singleton that is created lazily when first requested.
  void registerLazySingleton<T extends Object>(T Function() factory) {
    if (_factories.containsKey(T) || _singletons.containsKey(T)) {
      throw ServiceError.alreadyRegistered(T);
    }
    _factories[T] = _SyncServiceFactory<T>(factory);
  }

  /// Register an async singleton that is created lazily when first requested.
  void registerLazyAsyncSingleton<T extends Object>(Future<T> Function() factory) {
    if (_factories.containsKey(T) || _singletons.containsKey(T)) {
      throw ServiceError.alreadyRegistered(T);
    }
    _factories[T] = _AsyncServiceFactory<T>(factory);
  }

  /// Get a registered singleton instance. If the singleton is async and not yet
  /// created, this will wait for it to be created.
  Future<T> get<T extends Object>() async {
    // Check if instance already exists
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }

    // Check if async instance is being created
    if (_asyncSingletons.containsKey(T)) {
      return await _asyncSingletons[T]!.future as T;
    }

    // Get factory
    final factory = _factories[T];
    if (factory == null) {
      throw ServiceError.notRegistered(T);
    }

    // Create instance
    if (factory is _AsyncServiceFactory<T>) {
      final completer = Completer<Object>();
      _asyncSingletons[T] = completer;
      try {
        final instance = await factory.create();
        _singletons[T] = instance;
        completer.complete(instance);
        _asyncSingletons.remove(T);
        return instance;
      } catch (e) {
        completer.completeError(e);
        _asyncSingletons.remove(T);
        rethrow;
      }
    } else if (factory is _SyncServiceFactory<T>) {
      final instance = factory.create();
      _singletons[T] = instance;
      return instance;
    } else {
      throw ServiceError.notRegistered(T);
    }
  }

  /// Get a registered singleton instance synchronously. Will throw if the singleton
  /// is async and not yet created.
  T getSync<T extends Object>() {
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }
    if (_asyncSingletons.containsKey(T)) {
      throw ServiceError.asyncNotReady(T);
    }
    final factory = _factories[T];
    if (factory == null) {
      throw ServiceError.notRegistered(T);
    }
    if (factory is _AsyncServiceFactory) {
      throw ServiceError.asyncNotReady(T);
    }
    if (factory is _SyncServiceFactory<T>) {
      final instance = factory.create();
      _singletons[T] = instance;
      return instance;
    }
    throw ServiceError.notRegistered(T);
  }

  /// Check if a service type is registered
  bool isRegistered<T extends Object>() {
    return _factories.containsKey(T) || _singletons.containsKey(T);
  }

  /// Remove a registered service
  void unregister<T extends Object>() {
    _factories.remove(T);
    _singletons.remove(T);
    _asyncSingletons.remove(T);
  }

  /// Remove all registered services
  void reset() {
    _factories.clear();
    _singletons.clear();
    _asyncSingletons.clear();
  }

  /// Initialize all core services
  Future<void> initializeCoreServices() async {
    // Register SharedPreferences
    registerLazyAsyncSingleton<SharedPreferences>(
      SharedPreferences.getInstance,
    );

    // Pre-register singleton services
    registerLazySingleton<BiometricService>(() => BiometricService.instance);
    registerLazySingleton<DeviceInfoService>(() => DeviceInfoService.instance);
    
    // Pre-initialize critical services
    final biometricService = await get<BiometricService>();
    final deviceInfoService = await get<DeviceInfoService>();

    // Initialize biometric and device services first
    await biometricService.initialize();
    await deviceInfoService.initialize();

    // Initialize auth service last (it depends on other services)
    await AuthService.initialize();
  }

  /// Dispose all services that need cleanup
  Future<void> dispose() async {
    final services = [..._singletons.values];
    for (final service in services) {
      if (service is BaseService) {
        service.dispose();
      }
    }
    reset();
  }
}

/// Base class for service factories
abstract class _ServiceFactory<T> {
  FutureOr<T> create();
}

/// Factory for synchronous service creation
class _SyncServiceFactory<T> extends _ServiceFactory<T> {
  final T Function() _factory;

  _SyncServiceFactory(this._factory);

  @override
  T create() => _factory();
}

/// Factory for asynchronous service creation
class _AsyncServiceFactory<T> extends _ServiceFactory<T> {
  final Future<T> Function() _factory;

  _AsyncServiceFactory(this._factory);

  @override
  Future<T> create() => _factory();
}
