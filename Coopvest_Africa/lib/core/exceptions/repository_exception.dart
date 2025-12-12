/// Custom exception class for repository errors
class RepositoryException implements Exception {
  final String message;
  final String operation;
  final dynamic innerException;
  final StackTrace? stackTrace;

  RepositoryException(
    this.message,
    this.operation, {
    this.innerException,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'RepositoryException: [$operation] $message';
  }
}
