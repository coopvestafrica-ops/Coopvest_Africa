import 'package:flutter/material.dart';

class ApiLogger {
  static void logRequest(String method, String url, {Map<String, dynamic>? headers, dynamic body}) {
    debugPrint('API Request: $method $url');
    if (headers != null) debugPrint('Headers: $headers');
    if (body != null) debugPrint('Body: $body');
  }

  static void logResponse(String method, String url, dynamic response, Duration duration) {
    debugPrint('API Response: $method $url (${duration.inMilliseconds}ms)');
    debugPrint('Response: $response');
  }

  static void logError(String method, String url, dynamic error, StackTrace stackTrace) {
    debugPrint('API Error: $method $url');
    debugPrint('Error: $error');
    debugPrint('Stack trace: $stackTrace');
  }
}

class ApiResponse<T> {
  final T? data;
  final String? error;
  final String? errorCode;
  final Map<String, dynamic>? errorData;
  final bool isLoading;
  final DateTime? timestamp;
  final Duration? retryAfter;
  final String? requestId; // For tracking specific requests
  final Duration? requestDuration; // How long the request took

  ApiResponse({
    this.data,
    this.error,
    this.errorCode,
    this.errorData,
    this.isLoading = false,
    this.timestamp,
    this.retryAfter,
    this.requestId,
    this.requestDuration,
  });

  factory ApiResponse.loading() => ApiResponse(
    isLoading: true,
    timestamp: DateTime.now(),
  );

  factory ApiResponse.success(T data) => ApiResponse(
    data: data,
    timestamp: DateTime.now(),
  );

  factory ApiResponse.error({
    required String error,
    String? errorCode,
    Map<String, dynamic>? errorData,
    Duration? retryAfter,
  }) => ApiResponse(
    error: error,
    errorCode: errorCode,
    errorData: errorData,
    retryAfter: retryAfter,
    timestamp: DateTime.now(),
  );

  bool get isSuccess => data != null && error == null && !isLoading;
  bool get isError => error != null && !isLoading;
  bool get hasRetryAfter => retryAfter != null;
  bool get isRetryable => isNetworkError || isServerError || isRateLimitError;
  
  // Error type checks
  bool get isRateLimitError => errorCode == 'RATE_LIMIT_EXCEEDED';
  bool get isAuthError => errorCode?.startsWith('AUTH_') ?? false;
  bool get isValidationError => errorCode?.startsWith('VALIDATION_') ?? false;
  bool get isNetworkError => errorCode?.startsWith('NETWORK_') ?? false;
  bool get isServerError => errorCode?.startsWith('SERVER_') ?? false;
  bool get isClientError => errorCode?.startsWith('CLIENT_') ?? false;
  bool get isTimeoutError => errorCode == 'TIMEOUT_ERROR';
  bool get isConnectionError => errorCode == 'CONNECTION_ERROR';
  bool get isMaintenanceError => errorCode == 'MAINTENANCE_ERROR';
  bool get isTokenExpiredError => errorCode == 'AUTH_TOKEN_EXPIRED';
  
  // Rate limiting info
  bool get shouldWaitBeforeRetry {
    final retry = retryTime;
    return hasRetryAfter && retry != null && DateTime.now().isBefore(retry);
  }
  
  DateTime? get retryTime => retryAfter != null ? DateTime.now().add(retryAfter!) : null;
  
  // Response age management
  static const defaultStaleAge = Duration(minutes: 5);
  bool get isStale => age > defaultStaleAge;
  bool get needsRefresh => isStale || isError;

  Duration get age => DateTime.now().difference(timestamp ?? DateTime.now());
  
  // Retry handling utilities
  static const maxRetries = 3;
  static const baseRetryDelay = Duration(seconds: 1);
  
  Duration calculateRetryDelay(int attempt) {
    if (hasRetryAfter) return retryAfter!;
    if (isRateLimitError) return const Duration(minutes: 1);
    return baseRetryDelay * (1 << (attempt - 1)); // Exponential backoff
  }
  
  bool shouldRetry(int attempt) {
    if (attempt >= maxRetries) return false;
    if (!isRetryable) return false;
    return true;
  }
  
  ApiResponse<T> copyWith({
    T? data,
    String? error,
    String? errorCode,
    Map<String, dynamic>? errorData,
    bool? isLoading,
    DateTime? timestamp,
    Duration? retryAfter,
  }) {
    return ApiResponse(
      data: data ?? this.data,
      error: error ?? this.error,
      errorCode: errorCode ?? this.errorCode,
      errorData: errorData ?? this.errorData,
      isLoading: isLoading ?? this.isLoading,
      timestamp: timestamp ?? this.timestamp,
      retryAfter: retryAfter ?? this.retryAfter,
    );
  }
}

class FormValidator {
  static const String _namePattern = '^[a-zA-Z\\s\\\'\\-]+\$';
  static const String _emailPattern = '^[a-zA-Z0-9.!#\$%&\\\'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*\$';
  static const String _specialCharPattern = '[!@#\$%^&*(),.?":{}|<>]';
  static const String _phonePattern = '[^\\d+]';
  
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(_emailPattern);
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? phone(String? value, [String? countryCode]) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final cleanNumber = value.replaceAll(RegExp(_phonePattern), '');
    
    if (countryCode != null && !cleanNumber.startsWith(countryCode)) {
      return 'Phone number must start with $countryCode';
    }

    if (cleanNumber.length < 10 || cleanNumber.length > 15) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  static String? password(String? value, {int minLength = 8, bool requireSpecialChar = true}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    if (requireSpecialChar && !value.contains(RegExp(_specialCharPattern))) {
      return 'Password must contain at least one special character';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? name(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Name'} is required';
    }
    if (value.trim().length < 2) {
      return '${fieldName ?? 'Name'} is too short';
    }
    final nameRegex = RegExp(_namePattern);
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Please enter a valid ${fieldName?.toLowerCase() ?? 'name'}';
    }
    return null;
  }
  
  static String? validateAmount(String? value, {double? min, double? max}) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    
    if (min != null && amount < min) {
      return 'Amount must be at least ${min.toStringAsFixed(2)}';
    }
    
    if (max != null && amount > max) {
      return 'Amount cannot exceed ${max.toStringAsFixed(2)}';
    }
    
    return null;
  }
  
  static String? validateDate(String? value, {DateTime? minDate, DateTime? maxDate}) {
    if (value == null || value.trim().isEmpty) {
      return 'Date is required';
    }
    
    final date = DateTime.tryParse(value);
    if (date == null) {
      return 'Please enter a valid date';
    }
    
    if (minDate != null && date.isBefore(minDate)) {
      return 'Date cannot be before ${minDate.toString().split(' ')[0]}';
    }
    
    if (maxDate != null && date.isAfter(maxDate)) {
      return 'Date cannot be after ${maxDate.toString().split(' ')[0]}';
    }
    
    return null;
  }

  static String? amount(String? value, {double? min, double? max}) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    
    if (min != null && amount < min) {
      return 'Amount must be at least ${min.toStringAsFixed(2)}';
    }
    
    if (max != null && amount > max) {
      return 'Amount cannot exceed ${max.toStringAsFixed(2)}';
    }
    
    return null;
  }

  static String? date(String? value, {DateTime? minDate, DateTime? maxDate}) {
    if (value == null || value.trim().isEmpty) {
      return 'Date is required';
    }
    
    final date = DateTime.tryParse(value);
    if (date == null) {
      return 'Please enter a valid date';
    }
    
    if (minDate != null && date.isBefore(minDate)) {
      return 'Date cannot be before ${minDate.toString().split(' ')[0]}';
    }
    
    if (maxDate != null && date.isAfter(maxDate)) {
      return 'Date cannot be after ${maxDate.toString().split(' ')[0]}';
    }
    
    return null;
  }
}

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final routeObserver = RouteObserver<PageRoute>();

  static NavigatorState get _navigator {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      throw StateError('NavigatorState not initialized. Make sure MaterialApp uses NavigationService.navigatorKey');
    }
    return navigator;
  }

  static Future<T?> push<T>(
    Widget page, {
    bool fullscreenDialog = false,
    Duration transitionDuration = const Duration(milliseconds: 300),
    RouteTransitionsBuilder? transitionsBuilder,
  }) {
    return _navigator.push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: transitionsBuilder ?? _defaultTransition,
        transitionDuration: transitionDuration,
        fullscreenDialog: fullscreenDialog,
      ),
    );
  }

  static Future<T?> pushReplacement<T, TO>(
    Widget page, {
    bool fullscreenDialog = false,
    Duration transitionDuration = const Duration(milliseconds: 300),
    RouteTransitionsBuilder? transitionsBuilder,
    TO? result,
  }) {
    return _navigator.pushReplacement<T, TO>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: transitionsBuilder ?? _defaultTransition,
        transitionDuration: transitionDuration,
        fullscreenDialog: fullscreenDialog,
      ),
      result: result,
    );
  }

  static Future<T?> pushAndRemoveUntil<T>(
    Widget page,
    bool Function(Route<dynamic>) predicate, {
    bool fullscreenDialog = false,
    Duration transitionDuration = const Duration(milliseconds: 300),
    RouteTransitionsBuilder? transitionsBuilder,
  }) {
    return _navigator.pushAndRemoveUntil<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: transitionsBuilder ?? _defaultTransition,
        transitionDuration: transitionDuration,
        fullscreenDialog: fullscreenDialog,
      ),
      predicate,
    );
  }

  static void pop<T>([T? result]) {
    if (_navigator.canPop()) {
      _navigator.pop<T>(result);
    }
  }

  static void popUntil(bool Function(Route<dynamic>) predicate) {
    _navigator.popUntil(predicate);
  }

  static void popToRoot() {
    _navigator.popUntil((route) => route.isFirst);
  }

  static Future<bool> maybePop<T>([T? result]) {
    return _navigator.maybePop<T>(result);
  }

  static bool canPop() {
    return _navigator.canPop();
  }

  static Widget _defaultTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeInOut;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }

  static Widget fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  static Widget scaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }
}
