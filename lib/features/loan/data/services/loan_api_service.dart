import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import '../../../../core/services/api_service.dart';
import '../exceptions/loan_exceptions.dart';
import '../network/request_manager.dart';
import '../models/loan.dart';
import '../models/loan_application.dart';
import '../models/loan_projection.dart';
import '../models/loan_product.dart';
import '../models/loan_eligibility.dart';
import '../models/loan_repayment.dart';
import '../models/document.dart';

@immutable
class LoanApiService {
  static const String baseUrl = 'https://api.coopvest.africa/v1';
  final ApiService _apiService;
  final RequestManager _requestManager;

  LoanApiService(
    this._apiService, {
    RequestManager? requestManager,
  }) : _requestManager = requestManager ?? RequestManager();

  Future<T> _handleRequest<T>(Future<T> Function() request) async {
    try {
      return await _requestManager.managed(request);
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } on SocketException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('HTTP client error: ${e.message}');
    } on FormatException catch (e) {
      throw ApiException('Invalid response format: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }

  void _validateResponse(Map<String, dynamic> response) {
    if (response.containsKey('errors')) {
      final errors = response['errors'] as Map<String, dynamic>;
      final validationErrors = <String, List<String>>{};
      
      errors.forEach((key, value) {
        if (value is List) {
          validationErrors[key] = value.map((e) => e.toString()).toList();
        } else {
          validationErrors[key] = [value.toString()];
        }
      });
      
      throw ValidationException(validationErrors);
    }
  }

  Future<List<Loan>> getLoans() async {
    return _handleRequest(() async {
      final loans = await _apiService.getList(
        '$baseUrl/loans',
        (map) => Loan.fromMap(map),
      );
      return loans;
    });
  }

  Future<Loan> getLoanDetails(String loanId) async {
    return _handleRequest(() async {
      final loan = await _apiService.get(
        '$baseUrl/loans/$loanId',
        Loan.fromMap,
      );
      return loan;
    });
  }

  Future<LoanApplication> applyForLoan({
    required String productId,
    required double amount,
    required int duration,
    required String purpose,
    required List<String> guarantorIds,
    required Map<String, dynamic> employmentDetails,
    required Map<String, dynamic> bankDetails,
    List<String>? documentIds,
  }) async {
    return _handleRequest(() async {
      final application = await _apiService.post(
        '$baseUrl/loans/apply',
        {
          'productId': productId,
          'amount': amount,
          'duration': duration,
          'purpose': purpose,
          'guarantorIds': guarantorIds,
          'employmentDetails': employmentDetails,
          'bankDetails': bankDetails,
          if (documentIds != null) 'documentIds': documentIds,
        },
        LoanApplication.fromMap,
      );
      return application;
    });
  }

  Future<List<LoanProduct>> getLoanProducts() async {
    return _handleRequest(() async {
      final products = await _apiService.getList(
        '$baseUrl/loans/products',
        (map) => LoanProduct.fromMap(map),
      );
      return products;
    });
  }

  Future<LoanEligibility> checkEligibility({
    required String productId,
    required double amount,
    required Map<String, dynamic> employmentDetails,
    required Map<String, dynamic> bankDetails,
    double? monthlyIncome,
    double? existingDebt,
    String? creditScore,
  }) async {
    return _handleRequest(() async {
      final eligibility = await _apiService.post(
        '$baseUrl/loans/eligibility',
        {
          'productId': productId,
          'amount': amount,
          'employmentDetails': employmentDetails,
          'bankDetails': bankDetails,
          if (monthlyIncome != null) 'monthlyIncome': monthlyIncome,
          if (existingDebt != null) 'existingDebt': existingDebt,
          if (creditScore != null) 'creditScore': creditScore,
        },
        LoanEligibility.fromMap,
      );
      return eligibility;
    });
  }

  Future<void> makeRepayment({
    required String loanId,
    required double amount,
    required String paymentMethod,
    String? referenceCode,
  }) async {
    return _handleRequest(() async {
      await _apiService.post(
        '$baseUrl/loans/repayment',
        {
          'loanId': loanId,
          'amount': amount,
          'paymentMethod': paymentMethod,
          if (referenceCode != null) 'referenceCode': referenceCode,
        },
        (map) => null,
      );
    });
  }

  Future<List<LoanRepayment>> getRepaymentSchedule(String loanId) async {
    return _handleRequest(() async {
      final repayments = await _apiService.getList(
        '$baseUrl/loans/$loanId/repayments',
        (map) => LoanRepayment.fromMap(map),
      );
      return repayments;
    });
  }

  Future<Map<String, dynamic>> getLoanStatistics() async {
    return _handleRequest(() async {
      final statistics = await _apiService.get(
        '$baseUrl/loans/statistics',
        (map) => map,
      );
      return statistics;
    });
  }

  Future<List<Document>> getLoanDocuments(String loanId) async {
    return _handleRequest(() async {
      final documents = await _apiService.getList(
        '$baseUrl/loans/$loanId/documents',
        (map) => Document.fromMap(map),
      );
      return documents;
    });
  }

  Future<String> uploadLoanDocument({
    required String loanId,
    required String documentType,
    required File file,
  }) async {
    return _handleRequest(() async {
      final uri = Uri.parse('$baseUrl/loans/$loanId/documents');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        ...request.headers,
        'Content-Type': 'multipart/form-data',
      });

      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
      );
      request.files.add(multipartFile);
      request.fields['documentType'] = documentType;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _validateResponse(data);
        return data['url'] as String;
      } else {
        throw ApiException(
          'Failed to upload document',
          statusCode: response.statusCode,
        );
      }
    });
  }

  Future<LoanProjection> calculateLoanProjection({
    required String productId,
    required double amount,
    required int duration,
    DateTime? startDate,
  }) async {
    return _handleRequest(() async {
      final projection = await _apiService.post(
        '$baseUrl/loans/projection',
        {
          'productId': productId,
          'amount': amount,
          'duration': duration,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
        },
        LoanProjection.fromMap,
      );
      return projection;
    });
  }

  Future<Map<String, dynamic>> getLoanTypeRequirements(String loanType) async {
    return _handleRequest(() async {
      final requirements = await _apiService.get(
        '$baseUrl/loans/types/$loanType/requirements',
        (map) => map,
      );
      return requirements;
    });
  }


}
