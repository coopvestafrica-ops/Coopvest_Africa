import 'dart:async';
import 'package:meta/meta.dart';

/// A utility class for rate limiting operations.
/// Uses token bucket algorithm for rate limiting.
@immutable
class RateLimiter {
  final int maxTokens;
  final Duration interval;
  final Map<String, _TokenBucket> _buckets = {};

  RateLimiter({
    required this.maxTokens,
    required this.interval,
  });

  /// Checks if an operation is allowed for the given key
  bool checkAndConsume(String key) {
    _cleanupExpiredBuckets();
    final bucket = _getBucket(key);
    return bucket.consumeToken();
  }

  /// Gets or creates a token bucket for the given key
  _TokenBucket _getBucket(String key) {
    final now = DateTime.now();
    if (!_buckets.containsKey(key) || _buckets[key]!.isExpired(now)) {
      _buckets[key] = _TokenBucket(
        maxTokens: maxTokens,
        interval: interval,
      );
    }
    return _buckets[key]!;
  }

  /// Removes expired buckets to prevent memory leaks
  void _cleanupExpiredBuckets() {
    final now = DateTime.now();
    _buckets.removeWhere((_, bucket) => bucket.isExpired(now));
  }

  /// Gets the time until the next token is available for a key
  Duration? timeToNextToken(String key) {
    final bucket = _buckets[key];
    if (bucket == null) return null;
    return bucket.timeToNextToken();
  }
}

/// Internal class representing a token bucket
class _TokenBucket {
  final int maxTokens;
  final Duration interval;
  int _tokens;
  DateTime _lastRefill;
  Timer? _refillTimer;

  _TokenBucket({
    required this.maxTokens,
    required this.interval,
  }) : _tokens = maxTokens,
       _lastRefill = DateTime.now() {
    _startRefillTimer();
  }

  bool consumeToken() {
    _refillTokens();
    if (_tokens > 0) {
      _tokens--;
      return true;
    }
    return false;
  }

  void _refillTokens() {
    final now = DateTime.now();
    final elapsedIntervals = now.difference(_lastRefill).inMicroseconds / 
                          interval.inMicroseconds;
    final tokensToAdd = (elapsedIntervals * maxTokens).floor();
    
    if (tokensToAdd > 0) {
      _tokens = (_tokens + tokensToAdd).clamp(0, maxTokens);
      _lastRefill = now;
    }
  }

  bool isExpired(DateTime now) {
    return now.difference(_lastRefill) > interval * 2;
  }

  Duration? timeToNextToken() {
    if (_tokens >= maxTokens) return null;
    final now = DateTime.now();
    final timeSinceLastRefill = now.difference(_lastRefill);
    final timePerToken = interval.inMicroseconds / maxTokens;
    final waitTime = Duration(
      microseconds: (timePerToken * (maxTokens - _tokens)).round(),
    ) - timeSinceLastRefill;
    return waitTime.isNegative ? Duration.zero : waitTime;
  }

  void _startRefillTimer() {
    _refillTimer?.cancel();
    _refillTimer = Timer.periodic(
      Duration(milliseconds: interval.inMilliseconds ~/ maxTokens),
      (_) => _refillTokens(),
    );
  }

  void dispose() {
    _refillTimer?.cancel();
  }
}
