/// Base class for all service errors
abstract class ServiceError extends Error {
  final String message;
  final Object? cause;
  @override
  final StackTrace? stackTrace;

  ServiceError(this.message, {this.cause, this.stackTrace});

  @override
  String toString() {
    var result = message;
    if (cause != null) {
      result += ': $cause';
    }
    if (stackTrace != null) {
      result += '\n$stackTrace';
    }
    return result;
  }
}

/// Error thrown when a requested service is not found
class ServiceNotFoundError extends ServiceError {
  final Type serviceType;

  ServiceNotFoundError(this.serviceType)
    : super('Service of type ${serviceType.toString()} not found. '
          'Make sure initializeServices() was called.');
}

/// Error thrown when there's an issue initializing services
class ServiceInitializationError extends ServiceError {
  ServiceInitializationError(super.message, {super.cause, super.stackTrace});
}

/// Error thrown when there's an issue disposing services
class ServiceDisposalError extends ServiceError {
  ServiceDisposalError(super.message, {super.cause, super.stackTrace});
}

/// Interface for disposable services
abstract class Disposable {
  Future<void> dispose();
}
