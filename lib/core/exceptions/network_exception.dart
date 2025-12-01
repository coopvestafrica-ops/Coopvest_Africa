/// Exception thrown when a network request fails due to connectivity issues.
class NetworkException implements Exception {
  final String message;
  final Duration? retryAfter;
  final bool isConnected;
  final String? host;

  NetworkException(
    this.message, {
    this.retryAfter,
    this.isConnected = false,
    this.host,
  });

  @override
  String toString() => 'NetworkException: $message'
    '${host != null ? ' (Host: $host)' : ''}'
    '${retryAfter != null ? ' (Retry after: ${retryAfter!.inSeconds}s)' : ''}';
}
