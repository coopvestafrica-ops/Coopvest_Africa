/// A generic result type that can represent either a success with a value or a failure with an error.
class Result<T> {
  final T? _value;
  final String? _error;
  final String? _errorCode;
  final Map<String, dynamic>? _errorData;

  Result.success(T value)
      : _value = value,
        _error = null,
        _errorCode = null,
        _errorData = null;

  Result.failure(String error, {String? errorCode, Map<String, dynamic>? errorData})
      : _value = null,
        _error = error,
        _errorCode = errorCode,
        _errorData = errorData;

  bool get isSuccess => _value != null;
  bool get isFailure => !isSuccess;

  T get value {
    if (isSuccess) {
      return _value!;
    }
    throw StateError('Cannot get value from failure result: $_error');
  }

  String get error {
    if (isFailure) {
      return _error!;
    }
    throw StateError('Cannot get error from success result');
  }

  String? get errorCode => _errorCode;
  Map<String, dynamic>? get errorData => _errorData;

  T getOrElse(T defaultValue) {
    return isSuccess ? _value! : defaultValue;
  }

  T? get valueOrNull => _value;

  Result<R> map<R>(R Function(T) transform) {
    if (isSuccess && _value is T) {
      try {
        return Result.success(transform(_value as T));
      } catch (e) {
        return Result.failure(e.toString());
      }
    }
    return Result.failure(_error ?? 'Unknown error', errorCode: _errorCode, errorData: _errorData);
  }

  Result<R> flatMap<R>(Result<R> Function(T) transform) {
    if (isSuccess && _value is T) {
      try {
        return transform(_value as T);
      } catch (e) {
        return Result.failure(e.toString());
      }
    }
    return Result.failure(_error ?? 'Unknown error', errorCode: _errorCode, errorData: _errorData);
  }

  void fold({
    required void Function(T) onSuccess,
    required void Function(String, {String? errorCode, Map<String, dynamic>? errorData}) onFailure,
  }) {
    if (isSuccess && _value is T) {
      onSuccess(_value as T);
    } else {
      onFailure(_error ?? 'Unknown error', errorCode: _errorCode, errorData: _errorData);
    }
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'Success($_value)';
    } else {
      return 'Failure($_error${_errorCode != null ? ', code: $_errorCode' : ''}${_errorData != null ? ', data: $_errorData' : ''})';
    }
  }
}
