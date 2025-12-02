class CancellationToken {
  bool _isCancelled = false;
  final List<Function()> _listeners = [];

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (!_isCancelled) {
      _isCancelled = true;
      for (final listener in _listeners) {
        listener();
      }
    }
  }

  void addListener(Function() listener) {
    if (!_isCancelled) {
      _listeners.add(listener);
    } else {
      listener();
    }
  }

  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  void dispose() {
    _listeners.clear();
  }
}
