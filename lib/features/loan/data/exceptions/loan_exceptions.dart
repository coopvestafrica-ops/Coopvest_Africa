/// Custom exceptions for loan-related operations.
library;

/// Exception thrown when an API request fails.
/// Contains the error message, HTTP status code, and any additional data returned by the API.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() =>
      'ApiException: $message ${statusCode != null ? "(Status: $statusCode)" : ""}';
}

/// Exception thrown when a network-related error occurs.
/// Contains the error message and the original exception that caused the error.
class NetworkException implements Exception {
  final String message;
  final Exception? originalError;

  NetworkException(this.message, [this.originalError]);

  @override
  String toString() =>
      'NetworkException: $message${originalError != null ? " (Cause: $originalError)" : ""}';
}

/// Exception thrown when request validation fails.
/// Contains a map of field names to lists of error messages.
class ValidationException implements Exception {
  final Map<String, List<String>> errors;

  ValidationException(this.errors);

  /// Returns the first error message for a given field, if any.
  String? getFirstError(String field) => errors[field]?.first;

  /// Returns all error messages for a given field, if any.
  List<String>? getFieldErrors(String field) => errors[field];

  /// Returns whether there are any errors for a given field.
  bool hasFieldErrors(String field) =>
      errors.containsKey(field) && errors[field]!.isNotEmpty;

  /// Returns a flattened list of all error messages.
  List<String> getAllErrors() {
    return errors.entries
        .expand((entry) => entry.value.map((error) => '${entry.key}: $error'))
        .toList();
  }

  @override
  String toString() {
    final allErrors = getAllErrors();
    return 'ValidationException: ${allErrors.join(", ")}';
  }
}
