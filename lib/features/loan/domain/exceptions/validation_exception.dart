import 'package:meta/meta.dart';
import 'loan_exception.dart';

@immutable
class ValidationException extends LoanException {
  @override
  final String? code;

  const ValidationException(
    super.message, {
    String? code,
    int? statusCode,
  }) : super(code: code, statusCode: statusCode);

  @override
  String toString() =>
      'ValidationException: $message${code != null ? ' (code: $code)' : ''}';
}
