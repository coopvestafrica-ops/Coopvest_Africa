import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/base_service.dart';
import '../../../../core/utils/connectivity_checker.dart';
import '../exceptions/loan_exception.dart';
import '../models/loan_application.dart';
import '../models/loan_status.dart';
import '../models/loan_guarantor.dart';

class LoanService extends BaseService {
  static LoanService? _instance;
  static LoanService get instance => _instance ??= LoanService._internal();

  final AuthService _authService;
  final ConnectivityChecker _connectivityChecker;
  static const _timeout = Duration(seconds: 30);

  LoanService._internal({
    AuthService? authService,
    ConnectivityChecker? connectivityChecker,
  }) : _authService = authService ?? AuthService.instance,
       _connectivityChecker = connectivityChecker ?? ConnectivityChecker();

  factory LoanService({
    AuthService? authService,
    ConnectivityChecker? connectivityChecker,
  }) {
    return instance;
  }

  Future<LoanStatus> getLoanStatus(String loanId) async {
    await _checkConnectivity();
    
    try {
      final token = await _authService.getToken();
      final response = await client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/loans/$loanId/status'),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return LoanStatus.fromJson(json.decode(response.body));
      } else {
        throw _handleError(response);
      }
    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  Future<List<LoanGuarantor>> getGuarantors(String loanId) async {
    await _checkConnectivity();
    
    try {
      final token = await _authService.getToken();
      final response = await client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/loans/$loanId/guarantors'),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final guarantors = List<Map<String, dynamic>>.from(data['guarantors']);
        return guarantors.map((g) => LoanGuarantor.fromJson(g)).toList();
      } else {
        throw _handleError(response);
      }
    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  Future<LoanGuarantor> getGuarantorStatus(String loanId, String guarantorId) async {
    await _checkConnectivity();
    
    try {
      final token = await _authService.getToken();
      final response = await client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/loans/$loanId/guarantors/$guarantorId'),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return LoanGuarantor.fromJson(json.decode(response.body));
      } else {
        throw _handleError(response);
      }
    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  Future<LoanApplication> submitLoanApplication(LoanApplication application) async {
    await _checkConnectivity();
    
    try {
      final token = await _authService.getToken();
      final response = await client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/loans/apply'),
            headers: _getHeaders(token),
            body: json.encode(application.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        return LoanApplication.fromJson(json.decode(response.body));
      } else {
        throw _handleError(response);
      }
    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  Future<void> cancelLoanApplication(String loanId) async {
    await _checkConnectivity();
    
    try {
      final token = await _authService.getToken();
      final response = await client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/loans/$loanId/cancel'),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw _handleError(response);
      }
    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  Future<Map<String, dynamic>> calculateLoanEligibility() async {
    await _checkConnectivity();
    
    try {
      final token = await _authService.getToken();
      final response = await client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/loans/eligibility'),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw _handleError(response);
      }
    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  Future<bool> checkGuarantorEligibility(String memberId) async {
    await _checkConnectivity();
    
    try {
      final token = await _authService.getToken();
      final response = await client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/loans/guarantor-eligibility/$memberId'),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['eligible'] == true;
      } else {
        throw _handleError(response);
      }
    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  Map<String, String> _getHeaders(String? token) {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<void> _checkConnectivity() async {
    if (!await _connectivityChecker.hasConnection) {
      throw const LoanException('No internet connection. Please check your network and try again.');
    }
  }

  LoanException _handleError(http.Response response) {
    try {
      final errorData = json.decode(response.body);
      return LoanException(
        errorData['message'] ?? errorData['error'] ?? 'An error occurred',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return LoanException(
        _getDefaultErrorMessage(response.statusCode),
        statusCode: response.statusCode,
      );
    }
  }

  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'This operation cannot be completed due to a conflict.';
      case 422:
        return 'The provided data is invalid.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'An internal server error occurred. Please try again later.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  LoanException _formatError(dynamic error) {
    if (error is LoanException) return error;
    if (error is TimeoutException) {
      return const LoanException('The request timed out. Please try again.');
    }
    return LoanException(error.toString());
  }

  // Removed unnecessary override of dispose()
}
