import 'dart:async';
import 'dart:io';
import 'dart:math' show pow;

/// A manager for handling HTTP requests with retry, timeout, and error handling capabilities.
/// 
/// Features:
/// - Automatic retries for failed requests
/// - Configurable timeout duration
/// - Exponential backoff for retries
/// - Custom error handling for specific exception types
class RequestManager {
  /// The maximum time to wait for a request to complete.
  final Duration timeout;

  /// The maximum number of times to retry a failed request.
  final int maxRetries;

  /// The base delay between retries. The actual delay will increase exponentially.
  final Duration retryDelay;

  /// Default retryable exceptions
  static final defaultRetryableExceptions = [
    TimeoutException,
    SocketException,
    HttpException,
  ];

  /// Creates a new [RequestManager] with the specified configuration.
  /// 
  /// - [timeout]: Maximum time to wait for a request (default: 30 seconds)
  /// - [maxRetries]: Maximum number of retry attempts (default: 3)
  /// - [retryDelay]: Base delay between retries (default: 2 seconds)
  const RequestManager({
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
  });

  /// Retries a failed operation with exponential backoff.
  /// 
  /// - [operation]: The async operation to retry
  /// - [currentRetry]: The current retry attempt (used internally)
  /// - [retryableExceptions]: List of exception types that should trigger a retry
  /// 
  /// Returns the result of the operation if successful, or throws the last error if all retries fail.
  Future<T> retry<T>(
    Future<T> Function() operation, {
    int currentRetry = 0,
    List<Type> retryableExceptions = const [],
  }) async {
    try {
      return await operation();
    } catch (error) {
      final exceptions = retryableExceptions.isEmpty 
          ? defaultRetryableExceptions 
          : retryableExceptions;

      if (currentRetry < maxRetries &&
          exceptions.any((type) => error.runtimeType == type)) {
        // Calculate delay with exponential backoff (2^retry * base delay)
        final delay = retryDelay * pow(2, currentRetry);
        print('Request failed with ${error.runtimeType}. Retrying in ${delay.inSeconds}s...');
        
        await Future.delayed(delay);
        return retry(
          operation,
          currentRetry: currentRetry + 1,
          retryableExceptions: retryableExceptions,
        );
      }
      rethrow;
    }
  }

  /// Wraps an operation with a timeout.
  /// 
  /// - [operation]: The async operation to timeout
  /// - [customTimeout]: Optional custom timeout duration
  /// 
  /// Throws a [TimeoutException] if the operation takes longer than the timeout duration.
  Future<T> withTimeout<T>(
    Future<T> Function() operation, {
    Duration? customTimeout,
  }) async {
    return operation().timeout(
      customTimeout ?? timeout,
      onTimeout: () => throw TimeoutException(
        'Request timed out after ${(customTimeout ?? timeout).inSeconds} seconds',
      ),
    );
  }

  /// Manages an operation with both retry and timeout functionality.
  /// 
  /// - [operation]: The async operation to manage
  /// - [retryableExceptions]: Optional list of exceptions that should trigger a retry
  /// - [customTimeout]: Optional custom timeout duration
  /// 
  /// This is the recommended way to wrap operations as it provides both retry and timeout functionality.
  Future<T> managed<T>(
    Future<T> Function() operation, {
    List<Type> retryableExceptions = const [],
    Duration? customTimeout,
  }) async {
    return retry(
      () => withTimeout(operation, customTimeout: customTimeout),
      retryableExceptions: retryableExceptions,
    );
  }
}
