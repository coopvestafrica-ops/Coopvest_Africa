import 'package:meta/meta.dart';
import 'loan_exception.dart';

@immutable
class ValidationException extends LoanException {
  @override
  final String? code;

  const ValidationException(
    super.message, {
    super.code,
    super.statusCode,
  });

  @override
  String toString() =>
      'ValidationException: $message${code != null ? ' (code: $code)' : ''}';
}
