/// Exception thrown when a loan eligibility check fails.
class EligibilityException implements Exception {
  /// The error message
  final String message;
  
  /// An optional error code for more specific error handling
  final String? code;

  /// An optional map of additional error details
  final Map<String, dynamic>? details;

  const EligibilityException(
    this.message, {
    this.code,
    this.details,
  });

  @override
  String toString() => 'EligibilityException: $message${code != null ? ' (code: $code)' : ''}';
}
