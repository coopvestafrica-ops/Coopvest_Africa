import 'package:meta/meta.dart';
import 'loan_exception.dart';

@immutable
class ValidationException extends LoanException {

  const ValidationException(
    super.message, {
    super.code,
    super.statusCode,
  });

  @override
  String toString() =>
      'ValidationException: $message${code != null ? ' (code: $code)' : ''}';
}
