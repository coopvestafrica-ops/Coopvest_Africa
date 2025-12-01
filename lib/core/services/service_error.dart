/// Base class for service locator errors
class ServiceError extends Error {
  final String message;
  final Type serviceType;

  ServiceError._(this.message, this.serviceType);

  /// Creates an error for when a service is already registered
  factory ServiceError.alreadyRegistered(Type serviceType) {
    return ServiceError._(
      'Service of type $serviceType is already registered',
      serviceType,
    );
  }

  /// Creates an error for when a service is not registered
  factory ServiceError.notRegistered(Type serviceType) {
    return ServiceError._(
      'No service of type $serviceType has been registered',
      serviceType,
    );
  }

  /// Creates an error for when an async service is not ready
  factory ServiceError.asyncNotReady(Type serviceType) {
    return ServiceError._(
      'Async service of type $serviceType is not ready',
      serviceType,
    );
  }

  @override
  String toString() => 'ServiceError: $message';
}
