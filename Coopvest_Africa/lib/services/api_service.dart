import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/connectivity_checker.dart';
import '../core/network/api_request.dart';
import '../core/network/api_response.dart';
import '../core/network/api_cache.dart';

class ApiService {
  final SharedPreferences _prefs;
  final ConnectivityChecker _connectivityChecker;
  final ApiCache _cache;
  final Duration _defaultTimeout;
  final int _maxRetries;

  static const String baseUrl = 'https://api.coopvest.africa/wp-json/coopvest/v1';
  static const String wpJsonUrl = 'https://api.coopvest.africa/wp-json/jwt-auth/v1';
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration defaultCacheTTL = Duration(minutes: 5);
  static const int defaultMaxRetries = 3;

  ApiService({
    required SharedPreferences prefs,
    required ConnectivityChecker connectivityChecker,
    Duration defaultTimeout = defaultTimeout,
    int maxRetries = defaultMaxRetries,
  })  : _prefs = prefs,
        _connectivityChecker = connectivityChecker,
        _cache = ApiCache(prefs: prefs, defaultTTL: defaultCacheTTL),
        _defaultTimeout = defaultTimeout,
        _maxRetries = maxRetries;

  // Token management
  Future<String?> getToken() async {
    return _prefs.getString(tokenKey);
  }

  Future<void> setToken(String token) async {
    await _prefs.setString(tokenKey, token);
  }

  Future<void> clearToken() async {
    await _prefs.remove(tokenKey);
  }

  bool get isAuthenticated => _prefs.containsKey(tokenKey);

  // Cache management
  Future<void> clearCache() async {
    await _cache.clearAll();
  }

  Future<void> clearProfileCache() async {
    await _cache.clear('member_profile');
  }

  // Connectivity helpers
  Future<bool> get hasConnection => _connectivityChecker.hasConnection;
  
  Stream<bool> get connectivityStream => 
      _connectivityChecker.onConnectivityChanged.map((state) => !state.isDisconnected);

  // Request helpers
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<ApiRequest> _createRequest(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final headers = requiresAuth ? await getAuthHeaders() : null;
    
    return ApiRequest(
      url: '$baseUrl/$path',
      method: method,
      connectivityChecker: _connectivityChecker,
      headers: headers,
      body: body,
      timeout: timeout ?? _defaultTimeout,
      maxRetries: _maxRetries,
      requiresAuth: requiresAuth,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> register(Map<String, dynamic> formData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/member/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': formData['email'],
          'email': formData['email'],
          'password': formData['password'],
          'first_name': formData['first_name'],
          'last_name': formData['last_name'],
          'meta': {
            'phone': formData['phone'],
            'date_of_birth': formData['date_of_birth'],
            'gender': formData['gender'],
            'bvn': formData['bvn'],
            'employer': formData['employer'],
            'job_title': formData['job_title'],
            'employment_date': formData['employment_date'],
            'monthly_income': formData['monthly_income'],
            'bank_name': formData['bank_name'],
            'account_number': formData['account_number'],
            'next_of_kin': {
              'name': formData['nok_name'],
              'relationship': formData['nok_relationship'],
              'phone': formData['nok_phone'],
              'address': formData['nok_address'],
            },
          },
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return ApiSuccess(data: {
          'success': true,
          'message': 'Registration successful! Please check your email to verify your account.',
          'data': data,
        });
      } else {
        return ApiError(
          message: data['message'] ?? 'Registration failed',
          errorCode: 'REGISTRATION_FAILED',
        );
      }
    } catch (e) {
      return ApiError(
        message: 'Network error: ${e.toString()}',
        errorCode: ApiErrorType.network.code,
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> login(String username, String password) async {
    try {
      // First, authenticate with WordPress JWT
      final response = await http.post(
        Uri.parse('$wpJsonUrl/token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      final authData = json.decode(response.body);
      
      if (response.statusCode == 200 && authData['token'] != null) {
        final token = authData['token'];
        await setToken(token);

        // Then get user profile data
        final profileRequest = await _createRequest('member/profile');
        final userResponse = await profileRequest.execute<Map<String, dynamic>>(
          responseConverter: (dynamic json) => json as Map<String, dynamic>,
        );

        if (userResponse.success && userResponse.data != null) {
          final userData = userResponse.data!;
          await _prefs.setString(userIdKey, userData['id'].toString());
          await _prefs.setString('user_data', json.encode(userData));

          return ApiSuccess(data: {
            'success': true,
            'user': userData,
            'token': token,
          });
        }
      }

      return ApiError(
        message: authData['message'] ?? 'Login failed',
        errorCode: ApiErrorType.auth.code,
      );
    } catch (e) {
      return ApiError(
        message: 'Network error: ${e.toString()}',
        errorCode: ApiErrorType.network.code,
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getMemberProfile() async {
    const cacheKey = 'member_profile';
    
    // Try to get from cache first
    final cachedData = _cache.get<Map<String, dynamic>>(
      cacheKey,
      (dynamic json) => json as Map<String, dynamic>,
    );
    if (cachedData != null) {
      return ApiSuccess(data: cachedData);
    }

    // Get fresh data from API
    if (!isAuthenticated) {
      return ApiError(
        message: 'Not authenticated',
        errorCode: ApiErrorType.auth.code,
      );
    }

    try {
      final request = await _createRequest('member/profile');
      final response = await request.execute<Map<String, dynamic>>(
        responseConverter: (dynamic json) => json as Map<String, dynamic>,
      );

      // Cache successful responses
      if (response.success && response.data != null) {
        await _cache.set(cacheKey, response.data);
      }

      return response;
    } catch (e) {
      return ApiError(
        message: e.toString(),
        errorCode: ApiErrorType.unknown.code,
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getWalletBalance() async {
    try {
      final request = await _createRequest('wallet/balance');
      return await request.execute<Map<String, dynamic>>(
        responseConverter: (json) => json,
      );
    } catch (e) {
      return ApiError(
        message: e.toString(),
        errorCode: ApiErrorType.unknown.code,
      );
    }
  }

  Future<ApiResponse<List<dynamic>>> getWalletTransactions({int page = 1}) async {
    try {
      final request = await _createRequest('wallet/transactions?page=$page');
      return await request.execute<List<dynamic>>(
        responseConverter: (json) => json as List<dynamic>,
      );
    } catch (e) {
      return ApiError(
        message: e.toString(),
        errorCode: ApiErrorType.unknown.code,
      );
    }
  }

  Future<ApiResponse<List<dynamic>>> getLoans() async {
    try {
      final request = await _createRequest('loans');
      return await request.execute<List<dynamic>>(
        responseConverter: (json) => json as List<dynamic>,
      );
    } catch (e) {
      return ApiError(
        message: e.toString(),
        errorCode: ApiErrorType.unknown.code,
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> applyForLoan(Map<String, dynamic> loanData) async {
    try {
      final request = await _createRequest(
        'loans/apply',
        method: 'POST',
        body: loanData,
      );
      return await request.execute<Map<String, dynamic>>(
        responseConverter: (dynamic json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiError(
        message: e.toString(),
        errorCode: ApiErrorType.unknown.code,
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> rolloverLoan(Map<String, dynamic> rolloverData) async {
    try {
      final request = await _createRequest(
        'loans/rollover',
        method: 'POST',
        body: rolloverData,
      );
      return await request.execute<Map<String, dynamic>>(
        responseConverter: (dynamic json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiError(
        message: e.toString(),
        errorCode: ApiErrorType.unknown.code,
      );
    }
  }

  Future<ApiResponse<List<dynamic>>> getContributions() async {
    try {
      final request = await _createRequest('contributions');
      return await request.execute<List<dynamic>>(
        responseConverter: (json) => json as List<dynamic>,
      );
    } catch (e) {
      return ApiError(
        message: e.toString(),
        errorCode: ApiErrorType.unknown.code,
      );
    }
  }

  Future<ApiResponse<List<dynamic>>> getReferrals() async {
    try {
      final request = await _createRequest('referrals');
      return await request.execute<List<dynamic>>(
        responseConverter: (json) => json as List<dynamic>,
      );
    } catch (e) {
      return ApiError(
        message: e.toString(),
        errorCode: ApiErrorType.unknown.code,
      );
    }
  }

  Future<ApiResponse<List<dynamic>>> getInvestments() async {
    try {
      final request = await _createRequest('investments');
      return await request.execute<List<dynamic>>(
        responseConverter: (json) => json as List<dynamic>,
      );
    } catch (e) {
      return ApiError(
        message: e.toString(),
        errorCode: ApiErrorType.unknown.code,
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getFeatureStatus() async {
    try {
      final request = await _createRequest('features/status');
      return await request.execute<Map<String, dynamic>>(
        responseConverter: (dynamic json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiError(
        message: e.toString(),
        errorCode: ApiErrorType.unknown.code,
      );
    }
  }
}
