abstract class ApiEvent {
  const ApiEvent();
}

class RequestStarted extends ApiEvent {
  final String method;
  final String path;
  final Map<String, dynamic>? body;

  const RequestStarted({
    required this.method,
    required this.path,
    this.body,
  });
}

class RequestCompleted extends ApiEvent {
  final String method;
  final String path;
  final int statusCode;
  final Duration duration;

  const RequestCompleted({
    required this.method,
    required this.path,
    required this.statusCode,
    required this.duration,
  });
}

class RequestFailed extends ApiEvent {
  final String method;
  final String path;
  final String error;
  final int? statusCode;
  final Duration duration;
  final bool willRetry;

  const RequestFailed({
    required this.method,
    required this.path,
    required this.error,
    this.statusCode,
    required this.duration,
    required this.willRetry,
  });
}

class CacheHit extends ApiEvent {
  final String path;
  final Duration age;

  const CacheHit({
    required this.path,
    required this.age,
  });
}

class RateLimitExceeded extends ApiEvent {
  final String method;
  final String path;
  final Duration resetAfter;

  const RateLimitExceeded({
    required this.method,
    required this.path,
    required this.resetAfter,
  });
}
