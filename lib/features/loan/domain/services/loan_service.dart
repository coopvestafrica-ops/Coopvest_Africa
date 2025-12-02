import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/exceptions/network_exception.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/base_service.dart';
import '../../../../core/utils/connectivity_checker.dart';
import '../../../../core/utils/rate_limiter.dart';
import '../exceptions/loan_exception.dart';
import '../exceptions/eligibility_exception.dart';
import '../exceptions/validation_exception.dart';
import '../models/loan_application.dart';
import '../models/loan_service_interface.dart';
import '../models/loan_status.dart';
import '../models/loan_guarantor.dart';
import '../models/loan_submission_result.dart';
import '../models/rollover_eligibility.dart';
import '../models/rollover_request.dart';

/// Service responsible for handling all loan-related operations.
/// Implements [LoanServiceInterface] to provide standardized loan functionality.
class LoanService extends BaseService implements LoanServiceInterface {
  static LoanService? _instance;
  static LoanService get instance => _instance ??= LoanService._internal();

  @override
  Future<void> archiveLoan({
    required String loanId,
    required String reason,
    bool archivePayments = true,
    bool archiveDocuments = true,
  }) async {
    await _checkConnectivity();
    
    try {
      // Get loan details first to verify status
      final loan = await getLoanDetails(loanId: loanId, includePaymentHistory: archivePayments);
      final status = loan['status'] as String;

      if (status != 'completed' && status != 'defaulted') {
        throw const ValidationException(
          'Only completed or defaulted loans can be archived',
          code: 'INVALID_LOAN_STATUS'
        );
      }

      // Archive to a separate collection first
      await _lock.synchronized(() async {
        final archiveRef = _firestore.collection('archived_loans').doc(loanId);
        
        final currentUser = await _authService.getCurrentUser();
        if (currentUser == null) {
          throw StateError('No authenticated user found');
        }

        await archiveRef.set({
          ...loan,
          'archivedAt': FieldValue.serverTimestamp(),
          'archiveReason': reason,
          'archivedBy': currentUser.id,
        });

        // Archive related collections if requested
        if (archivePayments && loan['paymentHistory'] != null) {
          await archiveRef.collection('payments').add({
            'data': loan['paymentHistory'],
            'archivedAt': FieldValue.serverTimestamp(),
          });
        }

        if (archiveDocuments) {
          final docsRef = _firestore.collection('loan_documents').where('loanId', isEqualTo: loanId);
          final docs = await docsRef.get();
          
          if (docs.docs.isNotEmpty) {
            await archiveRef.collection('documents').add({
              'data': docs.docs.map((d) => d.data()).toList(),
              'archivedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        // Mark as archived in main collection
        final loanRef = _firestore.collection('loans').doc(loanId);
        await loanRef.update({
          'isArchived': true,
          'archivedAt': FieldValue.serverTimestamp(),
          'archiveReason': reason,
        });
      });

    } catch (e) {
      throw _formatError(e);
    }
  }

  @override
  Future<void> cancelRolloverRequest(String requestId) async {
    await _checkConnectivity();
    
    try {
      final token = await _authService.getToken();
      final response = await client.post(
        Uri.parse('${ApiConfig.baseUrl}/loans/rollover/$requestId/cancel'),
        headers: _getHeaders(token),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw _handleError(response);
      }

      // Update Firestore
      await _lock.synchronized(() async {
        final requestRef = _firestore.collection('rollover_requests').doc(requestId);
        await requestRef.update({
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  final AuthService _authService;
  final ConnectivityChecker _connectivityChecker;
  final FirebaseFirestore _firestore;
  final Lock _lock = Lock();
  
  static const _timeout = Duration(seconds: 30);
  static const _cacheDuration = Duration(minutes: 15);

  // Rate limiters for different operations
  final _applicationRateLimiter = RateLimiter(
    maxTokens: 3,
    interval: const Duration(minutes: 30),
  );

  final _rolloverRateLimiter = RateLimiter(
    maxTokens: 1,
    interval: const Duration(hours: 24),
  );

  final _guarantorRateLimiter = RateLimiter(
    maxTokens: 5,
    interval: const Duration(minutes: 60),
  );

  // Cache for loan details
  final Map<String, ({Map<String, dynamic> data, DateTime timestamp})> _loanCache = {};

  Future<Map<String, dynamic>> getLoanDetails({
    required String loanId,
    bool includePaymentHistory = false,
    bool includeGuarantors = false,
    bool useCache = true,
  }) async {
    await _checkConnectivity();
    
    try {
      // Check cache first
      if (useCache && _loanCache.containsKey(loanId)) {
        final cachedData = _loanCache[loanId]!;
        if (DateTime.now().difference(cachedData.timestamp) < _cacheDuration) {
          return cachedData.data;
        }
        // Remove expired cache entry
        _loanCache.remove(loanId);
      }

      final token = await _authService.getToken();
      final queryParams = {
        if (includePaymentHistory) 'includePayments': 'true',
        if (includeGuarantors) 'includeGuarantors': 'true',
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/loans/$loanId')
          .replace(queryParameters: queryParams);

      final response = await client
          .get(
            uri,
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Cache the response
        _loanCache[loanId] = (
          data: responseData,
          timestamp: DateTime.now(),
        );
        
        return responseData;
      } else {
        throw _handleError(response);
      }
    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }
  
  LoanService._internal({
    AuthService? authService,
    ConnectivityChecker? connectivityChecker,
    FirebaseFirestore? firestore,
    http.Client? client,
  }) : _authService = authService ?? AuthService.instance,
       _connectivityChecker = connectivityChecker ?? ConnectivityChecker(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       super(client: client ?? http.Client());

  Map<String, String> _getHeaders(String? token) {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // For testing purposes
  @visibleForTesting
  factory LoanService.forTesting({
    required AuthService authService,
    ConnectivityChecker? connectivityChecker,
    http.Client? client,
  }) {
    return LoanService._internal(
      authService: authService,
      connectivityChecker: connectivityChecker,
      client: client,
    );
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

  @override
  Future<void> updateLoanStatus({
    required String loanId,
    required String status,
    String? remarks,
  }) async {
    await _checkConnectivity();

    if (!LoanServiceInterface.validLoanStatuses.containsKey(status)) {
      // Can't make const due to string interpolation
      throw ValidationException(
          'Invalid loan status. Valid statuses are: ${LoanServiceInterface.validLoanStatuses.keys.join(", ")}',
          code: 'INVALID_STATUS'
        );
    }    try {
      final token = await _authService.getToken();
      final response = await client.patch(
        Uri.parse('${ApiConfig.baseUrl}/loans/$loanId/status'),
        headers: _getHeaders(token),
        body: json.encode({
          'status': status,
          'remarks': remarks,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw _handleError(response);
      }

      // Update Firestore
      await _lock.synchronized(() async {
        final loanRef = _firestore.collection('loans').doc(loanId);
        await loanRef.update({
          'status': status,
          'statusRemarks': remarks,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  @override
  @override
  Future<bool> validateLoanApplication(LoanApplication application) async {
    try {
      // Basic validation
      if (application.loanAmount <= 0) {
        throw const ValidationException('Loan amount must be greater than 0', code: 'INVALID_AMOUNT');
      }

      if (!LoanServiceInterface.validTenureMonths.contains(application.tenureMonths)) {
        throw ValidationException(
          'Invalid tenure. Valid options are: ${LoanServiceInterface.validTenureMonths.join(", ")} months',
          code: 'INVALID_TENURE'
        );
      }

      // Validate status
      if (application.status != null && 
          !LoanServiceInterface.validLoanStatuses.containsKey(application.status)) {
        throw ValidationException(
          'Invalid loan status. Valid statuses are: ${LoanServiceInterface.validLoanStatuses.keys.join(", ")}',
          code: 'INVALID_STATUS'
        );
      }

      // Check eligibility
      final eligibility = await calculateLoanEligibility();
      
      if (application.loanAmount > (eligibility['maxAmount'] ?? 0)) {
        // Can't make const due to string interpolation
        throw ValidationException(
          'Loan amount exceeds maximum eligible amount of ${eligibility['maxAmount']}',
          code: 'AMOUNT_EXCEEDS_MAX'
        );
      }

      // Validate guarantors if required
      if (application.guarantors != null && application.guarantors!.isNotEmpty) {
        for (final guarantor in application.guarantors!) {
          final isEligible = await checkGuarantorEligibility(
            userId: guarantor.userId,
            loanAmount: application.loanAmount,
            loanTenure: application.tenureMonths,
          );
          if (!(isEligible['isEligible'] as bool)) {
            // Can't make const due to string interpolation
            throw ValidationException(
              'Guarantor ${guarantor.userId} is not eligible: ${isEligible['reason']}',
              code: 'INELIGIBLE_GUARANTOR'
            );
          }
        }
      }

      return true;
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw _formatError(e);
    }
  }

  Future<Map<String, dynamic>> getUserLoanSummary({
    required String userId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
    int offset = 0,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    await _checkConnectivity();
    
    try {
      // Validate parameters
      if (status != null && !LoanServiceInterface.validLoanStatuses.containsKey(status)) {
        throw ValidationException(
          'Invalid loan status. Valid statuses are: ${LoanServiceInterface.validLoanStatuses.keys.join(", ")}',
          code: 'INVALID_STATUS'
        );
      }

      if (limit < 1 || limit > 100) {
        throw const ValidationException('Limit must be between 1 and 100', code: 'INVALID_LIMIT');
      }

      if (offset < 0) {
        throw const ValidationException('Offset cannot be negative', code: 'INVALID_OFFSET');
      }

      final token = await _authService.getToken();
      final queryParams = {
        'userId': userId,
        'limit': limit.toString(),
        'offset': offset.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        if (status != null) 'status': status,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/loans/user-summary')
          .replace(queryParameters: queryParams);

      final response = await client
          .get(
            uri,
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

  @override
  Future<Map<String, dynamic>> getUserLoanStatistics(String userId) async {
    await _checkConnectivity();
    
    try {
      final token = await _authService.getToken();
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/loans/statistics/$userId'),
        headers: _getHeaders(token),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw _handleError(response);
      }

      final stats = json.decode(response.body);

      // Add derived metrics
      if (stats['summary'] != null) {
        final summary = stats['summary'] as Map<String, dynamic>;
        
        if (summary['totalLoans'] != null && summary['totalLoans'] > 0) {
          // Calculate repayment rate
          if (summary['onTimePayments'] != null && summary['totalPayments'] != null) {
            summary['repaymentRate'] = 
              (summary['onTimePayments'] as num) / (summary['totalPayments'] as num) * 100;
          }

          // Calculate average loan amount
          if (summary['totalAmount'] != null) {
            summary['averageLoanAmount'] = 
              (summary['totalAmount'] as num) / (summary['totalLoans'] as num);
          }
        }
      }

      return stats;
    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  @override
  Future<List<LoanGuarantor>> getLoanGuarantors(String loanId) async {
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

  @override
  Future<LoanSubmissionResult> submitLoanApplication(LoanApplication application) async {
    await _checkConnectivity();
    
    try {
      // Check rate limit
      if (!_applicationRateLimiter.checkAndConsume(application.userId)) {
        final timeToNext = _applicationRateLimiter.timeToNextToken(application.userId);
        throw ValidationException(
          'Too many applications. Please wait ${timeToNext?.inMinutes ?? 30} minutes.',
          code: 'RATE_LIMIT_EXCEEDED'
        );
      }

      // Validate application first
      final isValid = await validateLoanApplication(application);
      if (!isValid) {
        return LoanSubmissionResult.failure(
          message: 'Invalid loan application',
          errorCode: 'VALIDATION_FAILED',
        );
      }

      // Submit to both API and Firestore for redundancy
      final token = await _authService.getToken();
      
      // Submit to API
      final response = await client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/loans/apply'),
            headers: _getHeaders(token),
            body: json.encode(application.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode != 201) {
        throw _handleError(response);
      }

      final responseData = json.decode(response.body);
      final loanId = responseData['id'] as String;

      // Store in Firestore
      await _lock.synchronized(() async {
        final loanRef = _firestore.collection('loans').doc(loanId);
        await loanRef.set({
          ...application.toJson(),
          'id': loanId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return LoanSubmissionResult.success(
        loanId: loanId,
        data: responseData,
      );
    } on ValidationException catch (e) {
      return LoanSubmissionResult.failure(
        message: e.message,
        errorCode: e.code,
      );
    } on TimeoutException {
      return LoanSubmissionResult.failure(
        message: 'Request timed out. Please try again.',
        errorCode: 'TIMEOUT',
      );
    } catch (e) {
      final error = _formatError(e);
      return LoanSubmissionResult.failure(
        message: error.message,
        errorCode: error.code,
      );
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

  @override
  Future<RolloverRequest> createRolloverRequest({
    required String oldLoanId,
    required String userId,
    required double newLoanAmount,
    required int newTenureMonths,
    String? reason,
    bool notifyGuarantors = true,
    List<String>? attachments,
  }) async {
    await _checkConnectivity();

    try {
      // Check rate limit
      if (!_rolloverRateLimiter.checkAndConsume(userId)) {
        final timeToNext = _rolloverRateLimiter.timeToNextToken(userId);
        throw ValidationException(
          'Too many rollover requests. Please wait ${timeToNext?.inHours ?? 24} hours.',
          code: 'RATE_LIMIT_EXCEEDED'
        );
      }

      // Verify rollover eligibility first
      final eligibility = await checkRolloverEligibility(oldLoanId);
      if (!eligibility.isEligible) {
        throw EligibilityException(
          eligibility.message,
          code: 'ROLLOVER_NOT_ELIGIBLE'
        );
      }

      if (newLoanAmount > (eligibility.maxAmount ?? 0)) {
        throw ValidationException(
          'New loan amount exceeds maximum allowed amount of ${eligibility.maxAmount}',
          code: 'AMOUNT_EXCEEDS_MAX'
        );
      }

      if (!eligibility.availableTenures!.contains(newTenureMonths)) {
        // Can't make const due to string interpolation
        throw ValidationException(
          'Invalid tenure. Available options are: ${eligibility.availableTenures!.join(", ")}',
          code: 'INVALID_TENURE'
        );
      }

      final token = await _authService.getToken();
      final response = await client.post(
        Uri.parse('${ApiConfig.baseUrl}/loans/rollover'),
        headers: _getHeaders(token),
        body: json.encode({
          'oldLoanId': oldLoanId,
          'userId': userId,
          'newLoanAmount': newLoanAmount,
          'newTenureMonths': newTenureMonths,
          'reason': reason,
          'notifyGuarantors': notifyGuarantors,
          'attachments': attachments,
        }),
      ).timeout(_timeout);

      if (response.statusCode != 201) {
        throw _handleError(response);
      }

      final responseData = json.decode(response.body);
      return RolloverRequest.fromMap(responseData);

    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  @override
  Future<RolloverRequest> approveRollover({
    required String requestId,
    required String guarantorId,
    String? verificationCode,
    String? comments,
  }) async {
    await _checkConnectivity();

    try {
      // Check rate limit for guarantor operations
      if (!_guarantorRateLimiter.checkAndConsume(guarantorId)) {
        final timeToNext = _guarantorRateLimiter.timeToNextToken(guarantorId);
        throw ValidationException(
          'Too many guarantor operations. Please wait ${timeToNext?.inMinutes ?? 60} minutes.',
          code: 'RATE_LIMIT_EXCEEDED'
        );
      }

      // Get request to check expiry
      final requestDoc = await _firestore.collection('rollover_requests').doc(requestId).get();
      if (!requestDoc.exists) {
        throw const ValidationException('Rollover request not found', code: 'NOT_FOUND');
      }

      final requestData = requestDoc.data()!;
      final createdAt = (requestData['createdAt'] as Timestamp).toDate();
      final expiryTime = createdAt.add(const Duration(hours: LoanServiceInterface.rolloverRequestExpiryHours));

      if (DateTime.now().isAfter(expiryTime)) {
        await _firestore.collection('rollover_requests').doc(requestId).update({
          'status': 'expired',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        throw const ValidationException(
          'Rollover request has expired. Please create a new request.',
          code: 'REQUEST_EXPIRED'
        );
      }

      final token = await _authService.getToken();
      final response = await client.post(
        Uri.parse('${ApiConfig.baseUrl}/loans/rollover/$requestId/approve'),
        headers: _getHeaders(token),
        body: json.encode({
          'guarantorId': guarantorId,
          'verificationCode': verificationCode,
          'comments': comments,
        }),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw _handleError(response);
      }

      final responseData = json.decode(response.body);
      return RolloverRequest.fromMap(responseData);

    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  @override
  Future<RolloverEligibility> checkRolloverEligibility(String loanId) async {
    await _checkConnectivity();

    try {
      // Get loan details to check payment percentage
      final loanDetails = await getLoanDetails(loanId: loanId);
      
      final originalAmount = (loanDetails['amount'] as num).toDouble();
      final amountPaid = (loanDetails['amountPaid'] as num?)?.toDouble() ?? 0.0;
      final paymentPercentage = (amountPaid / originalAmount) * 100;

      if (paymentPercentage < LoanServiceInterface.minPaymentPercentageForRollover) {
        return RolloverEligibility(
          isEligible: false,
          message: 'Must pay at least ${LoanServiceInterface.minPaymentPercentageForRollover}% of current loan',
          requirements: {
            'remainingAmount': originalAmount - amountPaid,
            'paymentPercentage': paymentPercentage,
            'minPaymentPercentage': LoanServiceInterface.minPaymentPercentageForRollover,
          },
        );
      }

      final token = await _authService.getToken();
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/loans/$loanId/rollover-eligibility'),
        headers: _getHeaders(token),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw _handleError(response);
      }

      final responseData = json.decode(response.body);
      final eligibility = RolloverEligibility.fromJson(responseData);

      // Add payment info to requirements
      if (eligibility.requirements != null) {
        eligibility.requirements!.addAll({
          'remainingAmount': originalAmount - amountPaid,
          'paymentPercentage': paymentPercentage,
          'minPaymentPercentage': LoanServiceInterface.minPaymentPercentageForRollover,
        });
      }

      return eligibility;

    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  @override
  Future<List<RolloverRequest>> getRolloverHistory(String userId) async {
    await _checkConnectivity();

    try {
      final token = await _authService.getToken();
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/loans/rollover-history/$userId'),
        headers: _getHeaders(token),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw _handleError(response);
      }

      final List<dynamic> data = json.decode(response.body);
      return data.map((request) => RolloverRequest.fromMap(request)).toList();

    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  @override
  Future<List<RolloverRequest>> getPendingRolloverRequests(String guarantorId) async {
    await _checkConnectivity();

    try {
      final token = await _authService.getToken();
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/loans/rollover-requests/$guarantorId/pending'),
        headers: _getHeaders(token),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw _handleError(response);
      }

      final List<dynamic> data = json.decode(response.body);
      return data.map((request) => RolloverRequest.fromMap(request)).toList();

    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> checkGuarantorEligibility({
    required String userId,
    required double loanAmount,
    required int loanTenure,
    bool checkCreditScore = true,
    bool checkIncome = true,
  }) async {
    await _checkConnectivity();
    
    try {
      final token = await _authService.getToken();
      final response = await client.post(
        Uri.parse('${ApiConfig.baseUrl}/loans/guarantor-eligibility'),
        headers: _getHeaders(token),
        body: json.encode({
          'userId': userId,
          'loanAmount': loanAmount,
          'loanTenure': loanTenure,
          'checkCreditScore': checkCreditScore,
          'checkIncome': checkIncome,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final eligibilityData = Map<String, dynamic>.from(responseData);

        // Validate against interface constants
        if (checkCreditScore && 
            (eligibilityData['metrics']?['creditScore'] ?? 0) < LoanServiceInterface.minGuarantorCreditScore) {
          eligibilityData['isEligible'] = false;
          eligibilityData['reason'] = 'Credit score below minimum requirement';
        }

        final totalGuaranteed = (eligibilityData['metrics']?['totalGuaranteed'] ?? 0.0) as double;
        final monthlyIncome = (eligibilityData['metrics']?['monthlyIncome'] ?? 0.0) as double;
        final maxGuaranteeAmount = monthlyIncome * (LoanServiceInterface.maxIncomeGuaranteePercentage / 100);

        if (checkIncome && totalGuaranteed + loanAmount > maxGuaranteeAmount) {
          eligibilityData['isEligible'] = false;
          eligibilityData['reason'] = 'Total guaranteed amount would exceed maximum allowed percentage of monthly income';
        }

        final activeGuarantees = (eligibilityData['metrics']?['activeGuarantees'] ?? 0) as int;
        if (activeGuarantees >= LoanServiceInterface.maxActiveGuarantees) {
          eligibilityData['isEligible'] = false;
          eligibilityData['reason'] = 'Maximum number of active guarantees reached';
        }

        return eligibilityData;
      } else {
        throw _handleError(response);
      }
    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  Future<void> _checkConnectivity() async {
    if (!await _connectivityChecker.hasConnection) {
      throw NetworkException('No internet connection. Please check your network and try again.');
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

  @override
  Future<void> cancelLoan(String loanId) async {
    await _checkConnectivity();
    
    try {
      final token = await _authService.getToken();
      final response = await client.delete(
        Uri.parse('${ApiConfig.baseUrl}/loans/$loanId'),
        headers: _getHeaders(token),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw _handleError(response);
      }

      // Update Firestore
      await _lock.synchronized(() async {
        final loanRef = _firestore.collection('loans').doc(loanId);
        await loanRef.update({
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  @override
  Future<LoanApplication> getLoanById(String loanId) async {
    await _checkConnectivity();
    
    try {
      final details = await getLoanDetails(loanId: loanId);
      return LoanApplication(
        id: details['id'] as String,
        userId: details['userId'] as String,
        type: details['type'] as String,
        loanAmount: (details['amount'] as num).toDouble(),
        tenureMonths: (details['tenureMonths'] as num).toInt(),
        purpose: details['purpose'] as String,
        monthlySavings: (details['monthlySavings'] as num).toDouble(),
        status: details['status'] as String,
        guarantors: details['guarantors'] != null
            ? (details['guarantors'] as List)
                .map((g) => LoanGuarantor.fromJson(g as Map<String, dynamic>))
                .toList()
            : null,
        submittedAt: details['submittedAt'] != null 
            ? DateTime.parse(details['submittedAt'] as String) 
            : null,
        updatedAt: details['updatedAt'] != null 
            ? DateTime.parse(details['updatedAt'] as String) 
            : null,
      );
    } catch (e) {
      throw _formatError(e);
    }
  }

  @override
  Future<List<LoanApplication>> getLoanHistory() async {
    await _checkConnectivity();
    
    try {
      final token = await _authService.getToken();
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/loans/history'),
        headers: _getHeaders(token),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw _handleError(response);
      }

      final List<dynamic> data = json.decode(response.body);
      return data
          .map((loan) => LoanApplication.fromJson(loan as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw const LoanException('Request timed out. Please try again.');
    } catch (e) {
      throw _formatError(e);
    }
  }

  @override
  void dispose() {
    client.close();
  }
}
