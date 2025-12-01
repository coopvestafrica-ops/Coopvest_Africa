class LoanException implements Exception {
  final String message;
  final dynamic originalError;
  final int? statusCode;
  final String? code;

  const LoanException(
    this.message, {
    this.originalError,
    this.statusCode,
    this.code,
  });

  @override
  String toString() => 'LoanException: $message${code != null ? ' (code: $code)' : ''}';

  bool get isNetworkError => originalError.toString().contains('SocketException') ||
                            originalError.toString().contains('TimeoutException');
  
  bool get isAuthError => statusCode == 401 || statusCode == 403;
}
