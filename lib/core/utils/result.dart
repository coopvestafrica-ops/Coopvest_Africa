class Result<T> {
  final T? _success;
  final String? _error;
  final String? _errorCode;
  final Map<String, dynamic>? _data;

  const Result.success(T value) 
      : _success = value,
        _error = null,
        _errorCode = null,
        _data = null;

  const Result.failure(
    String error, {
    String? errorCode,
    Map<String, dynamic>? data,
  }) : _success = null,
        _error = error,
        _errorCode = errorCode,
        _data = data;

  bool get isSuccess => _error == null;
  bool get isFailure => _error != null;
  T? get value => _success;
  String? get error => _error;
  String? get errorCode => _errorCode;
  Map<String, dynamic>? get data => _data;

  R when<R>({
    required R Function(T data) success,
    required R Function(String error, {String? errorCode, Map<String, dynamic>? data}) failure,
  }) {
    if (isSuccess) {
      return success(_success as T);
    } else {
      return failure(_error!, errorCode: _errorCode, data: _data);
    }
  }

  Result<R> map<R>(R Function(T data) transform) {
    if (isSuccess) {
      return Result.success(transform(_success as T));
    } else {
      return Result.failure(_error!, errorCode: _errorCode, data: _data);
    }
  }
}
