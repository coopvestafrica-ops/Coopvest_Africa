import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../../domain/models/loan_service_interface.dart';
import '../../domain/models/rollover_eligibility.dart';
import '../../domain/models/loan_guarantor.dart';
import '../../domain/models/rollover_request.dart';
import '../../domain/models/loan_application.dart' show LoanApplication;
import '../../domain/models/loan_submission_result.dart';
import '../../domain/exceptions/loan_exceptions.dart';

/// Cache management for loan details
class _LoanCache {
  final Map<String, ({
    Map<String, dynamic> data,
    DateTime timestamp
  })> _cache = {};
  
  static const _cacheDuration = Duration(minutes: 5);
  
  void set(String key, Map<String, dynamic> data) {
    _cache[key] = (
      data: data,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic>? get(String key) {
    final entry = _cache[key];
    if (entry == null || 
        DateTime.now().difference(entry.timestamp) >= _cacheDuration) {
      _cache.remove(key);
      return null;
    }
    return entry.data;
  }

  void remove(String key) => _cache.remove(key);
}

/// Rate limiting configuration
class _RateLimit {
  final Duration interval;
  final int maxRequests;
  final Map<String, List<DateTime>> _requestTimes = {};

  _RateLimit({
    required this.interval,
    required this.maxRequests,
  });

  bool checkAndRecord(String key) {
    final now = DateTime.now();
    final times = _requestTimes[key] ?? [];
    times.removeWhere((time) => now.difference(time) > interval);
    
    if (times.length >= maxRequests) {
      return false;
    }

    times.add(now);
    _requestTimes[key] = times;
    return true;
  }
}

/// Implementation of loan rollover service using Firestore
/// 
/// Required Firestore indices:
/// 1. loan_payments:
///    - Collection: loan_payments
///    - Fields to index: loanId Ascending, date Descending
///
/// 2. guarantees:
///    - Collection: guarantees
///    - Fields to index: loanId Ascending, status Ascending
///
/// 3. rollover_requests (for history):
///    - Collection: rollover_requests
///    - Fields to index: userId Ascending, createdAt Descending
///
/// 4. rollover_requests (for pending):
///    - Collection: rollover_requests
///    - Fields to index: status Ascending, createdAt Descending
///    - Array contains field: guarantors
class LoanRolloverService implements LoanServiceInterface {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _loanCache = _LoanCache();
  final _logger = Logger('LoanRolloverService');

  /// Rate limiter for rollover operations
  final _rolloverRateLimit = _RateLimit(
    interval: const Duration(minutes: 5),
    maxRequests: 3,
  );

  /// Rate limiter for approvals
  final _approvalRateLimit = _RateLimit(
    interval: const Duration(minutes: 1),
    maxRequests: 5,
  );

  /// Additional percentage required per 6 months of tenure
  static const double _additionalPercentagePerTenure = 5.0;

  @override
  Future<LoanSubmissionResult> submitLoanApplication(LoanApplication application) async {
    throw const LoanRolloverException(
      'LoanRolloverService does not support submitting new loan applications. '
      'Please use LoanService instead.'
    );
  }

  @override
  Future<bool> validateLoanApplication(LoanApplication application) async {
    throw const LoanRolloverException(
      'LoanRolloverService does not support validating loan applications. '
      'Please use LoanService instead.'
    );
  }

  @override
  @override
  Future<void> updateLoanStatus({
    required String loanId,
    required String status,
    String? remarks,
  }) async {
    try {
      if (!LoanServiceInterface.validLoanStatuses.containsKey(status)) {
        throw const ValidationException(
          'Invalid loan status',
          code: 'INVALID_STATUS'
        );
      }

      await _firestore.collection('loans').doc(loanId).update({
        'status': status,
        'lastUpdated': FieldValue.serverTimestamp(),
        if (remarks != null) 'statusRemarks': remarks,
      });
    } catch (e) {
      if (e is ValidationException) rethrow;
      _logger.severe('Failed to update loan status', e);
      throw LoanRolloverException('Failed to update loan status: ${e.toString()}');
    }
  }

  @override
  Future<void> cancelRolloverRequest(String requestId) async {
    try {
      final requestDoc = await _firestore
          .collection('rollover_requests')
          .doc(requestId)
          .get();
      
      if (!requestDoc.exists) {
        throw const NotFoundException('Rollover request not found');
      }

      final requestData = requestDoc.data()!;
      if (requestData['status'] != 'pending') {
        throw const ValidationException('Only pending requests can be cancelled');
      }

      await requestDoc.reference.update({
        'status': 'cancelled',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e is LoanException) rethrow;
      throw LoanRolloverException('Failed to cancel rollover request: ${e.toString()}');
    }
  }

  @override
  @override
  Future<RolloverEligibility> checkRolloverEligibility(String loanId) async {
    try {
      final loanDoc = await _firestore.collection('loans').doc(loanId).get();
      
      if (!loanDoc.exists) {
        return const RolloverEligibility(
          isEligible: false,
          message: 'Loan not found'
        );
      }

      final loanData = loanDoc.data()!;
      final double totalAmount = (loanData['amount'] as num?)?.toDouble() ?? 0.0;
      final double amountPaid = (loanData['amountPaid'] as num?)?.toDouble() ?? 0.0;
      final String status = loanData['status'] as String? ?? '';

      // Check if loan is active
      if (status != 'active') {
        return const RolloverEligibility(
          isEligible: false,
          message: 'Only active loans can be rolled over'
        );
      }

      // Calculate payment percentage
      final paymentPercentage = (amountPaid / totalAmount) * 100;

      // Check if minimum payment percentage is met
      if (paymentPercentage < LoanServiceInterface.minPaymentPercentageForRollover) {
        return RolloverEligibility(
          isEligible: false,
          message: 'Must pay at least ${LoanServiceInterface.minPaymentPercentageForRollover}% of current loan '
            '(Current: ${paymentPercentage.toStringAsFixed(1)}%)'
        );
      }

      // Check payment history
      final payments = await _firestore
          .collection('loan_payments')
          .where('loanId', isEqualTo: loanId)
          .orderBy('date', descending: true)
          .limit(3)
          .get();

      // Check for any missed payments in last 3 payments
      bool hasMissedPayments = payments.docs.any((doc) => doc.data()['status'] == 'missed');
      if (hasMissedPayments) {
        return const RolloverEligibility(
          isEligible: false,
          message: 'Must have good payment history with no missed payments'
        );
      }

      // Calculate available tenures based on payment history
      final availableTenures = LoanServiceInterface.validTenureMonths.where((tenure) => 
        paymentPercentage >= LoanServiceInterface.minPaymentPercentageForRollover + 
          ((tenure - LoanServiceInterface.validTenureMonths.first) / 6) * _additionalPercentagePerTenure
      ).toList();

      final maxAmount = totalAmount * (1 + LoanServiceInterface.maxLoanIncreasePercentage / 100);

      return RolloverEligibility(
        isEligible: true,
        message: 'Eligible for rollover',
        maxAmount: maxAmount,
        availableTenures: availableTenures,
        requirements: {
          'currentAmount': totalAmount,
          'amountPaid': amountPaid,
          'remainingAmount': totalAmount - amountPaid,
          'paymentPercentage': paymentPercentage,
          'minPaymentRequired': LoanServiceInterface.minPaymentPercentageForRollover,
          'additionalPerTenure': _additionalPercentagePerTenure,
        }
      );
    } catch (e) {
      throw LoanRolloverException(
        'Error checking eligibility: ${e.toString()}'
      );
    }
  }

  @override
  Future<LoanApplication> getLoanById(String loanId) async {
    try {
      final details = await getLoanDetails(
        loanId: loanId, 
        includePaymentHistory: true,
        includeGuarantors: true
      );
      return LoanApplication.fromJson(details);
    } catch (e) {
      if (e is LoanException) rethrow;
      throw LoanRolloverException('Error getting loan details: $e');
    }
  }

  // Helper method for internal use
  Future<Map<String, dynamic>> getLoanDetails({
    required String loanId,
    bool includePaymentHistory = false,
    bool includeGuarantors = false,
    bool useCache = true,
  }) async {
    try {
      // Check cache first
      if (useCache) {
        final cached = _loanCache.get(loanId);
        if (cached != null) {
          return cached;
        }
      }

      final loanDoc = await _firestore.collection('loans').doc(loanId).get();
      
      if (!loanDoc.exists) {
        throw const NotFoundException('Loan not found', code: 'LOAN_NOT_FOUND');
      }

      final loanData = Map<String, dynamic>.from(loanDoc.data()!);

      if (includePaymentHistory) {
        final payments = await _firestore
            .collection('loan_payments')
            .where('loanId', isEqualTo: loanId)
            .orderBy('date', descending: true)
            .get();

        loanData['paymentHistory'] = payments.docs
            .map((doc) => doc.data())
            .toList();
      }

      if (includeGuarantors) {
        loanData['guarantors'] = await getLoanGuarantors(loanId);
      }

      // Cache the result
      _loanCache.set(loanId, loanData);

      return loanData;
    } catch (e) {
      if (e is LoanException) rethrow;
      throw LoanRolloverException('Error getting loan details: $e');
    }
  }

  @override
  @override
  Future<List<LoanGuarantor>> getLoanGuarantors(String loanId) async {
    try {
      final guarantorDocs = await _firestore
          .collection('guarantees')
          .where('loanId', isEqualTo: loanId)
          .where('status', isEqualTo: 'active')
          .get();

      if (guarantorDocs.docs.isEmpty) {
        return [];
      }

      // Get all guarantor IDs and create a batch get for user data
      final guarantorIds = guarantorDocs.docs
          .map((doc) => doc.data()['guarantorId'] as String)
          .toSet();

      final usersData = await Future.wait(
        guarantorIds.map((id) => _firestore.collection('users').doc(id).get())
      );

      // Create a map of user data for quick lookup
      final userDataMap = Map.fromEntries(
        usersData.where((doc) => doc.exists).map((doc) => 
          MapEntry(doc.id, doc.data()!)
        )
      );

      // Build guarantor list with user data
      return guarantorDocs.docs.where((doc) {
        final guarantorId = doc.data()['guarantorId'] as String;
        return userDataMap.containsKey(guarantorId);
      }).map((doc) {
        final guarantee = doc.data();
        final userData = userDataMap[guarantee['guarantorId']]!;

        return LoanGuarantor(
          id: doc.id,
          userId: guarantee['guarantorId'] as String,
          fullName: '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim(),
          membershipId: userData['membershipId'] as String? ?? '',
          guaranteedAmount: (guarantee['amount'] as num?)?.toDouble() ?? 0.0,
          guaranteedAt: (guarantee['createdAt'] as Timestamp).toDate(),
          status: guarantee['status'] as String? ?? 'active'
        );
      }).toList();
    } catch (e) {
      throw LoanRolloverException('Error getting guarantors: $e');
    }
  }

  @override
  Future<void> cancelLoan(String loanId) async {
    throw const LoanRolloverException(
      'LoanRolloverService does not support cancelling loans. '
      'Please use LoanService instead.'
    );
  }

  @override
  Future<List<LoanApplication>> getLoanHistory() async {
    // Since this service handles rollovers, it can return history of rolled over loans
    try {
      // Use loan summary helper to get paginated history
      final summary = await _getUserLoanSummary(
        userId: '*', // Special value for all users
        status: 'rolled_over',
        limit: 1000, // Get a large batch
      );

      final List<Map<String, dynamic>> items = 
          List<Map<String, dynamic>>.from(summary['items']);

      return items.map((data) => LoanApplication.fromJson(data)).toList();
    } catch (e) {
      throw LoanRolloverException('Error getting loan history: $e');
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
    try {
      // Get user data
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw NotFoundException('User not found', code: 'USER_NOT_FOUND');
      }

      final userData = userDoc.data()!;

      // Get active guarantees
      final activeGuarantees = await _firestore
          .collection('guarantees')
          .where('guarantorId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      final totalGuaranteed = activeGuarantees.docs.fold<double>(
        0,
        (total, doc) => total + (doc.data()['amount'] as num).toDouble()
      );

      // Get user's credit score or rating
      final creditScore = (userData['creditScore'] as num?)?.toDouble() ?? 0;
      final monthlyIncome = (userData['monthlyIncome'] as num?)?.toDouble() ?? 0;

      // Calculate maximum guarantee amount (50% of monthly income)
      final maxMonthlyGuarantee = monthlyIncome * 0.5;
      final maxAmount = maxMonthlyGuarantee - totalGuaranteed;

      final isEligible = maxAmount >= loanAmount &&
          creditScore >= 600 &&  // Minimum credit score
          activeGuarantees.docs.length < 3;  // Max 3 active guarantees

      return {
        'isEligible': isEligible,
        'maxAmount': maxAmount,
        'reason': !isEligible ? _getIneligibilityReason(
          creditScore: creditScore,
          maxAmount: maxAmount,
          requestedAmount: loanAmount,
          activeGuaranteeCount: activeGuarantees.docs.length,
        ) : null,
        'metrics': {
          'creditScore': creditScore,
          'activeGuarantees': activeGuarantees.docs.length,
          'totalGuaranteed': totalGuaranteed,
          'monthlyIncome': monthlyIncome,
        }
      };
    } catch (e) {
      if (e is LoanException) rethrow;
      throw LoanRolloverException('Error checking guarantor eligibility: $e');
    }
  }

  String _getIneligibilityReason({
    required double creditScore,
    required double maxAmount,
    required double requestedAmount,
    required int activeGuaranteeCount,
  }) {
    if (creditScore < 600) {
      return 'Credit score too low (minimum: 600)';
    }
    if (activeGuaranteeCount >= 3) {
      return 'Maximum number of active guarantees reached (3)';
    }
    if (maxAmount < requestedAmount) {
      return 'Requested amount exceeds maximum guarantee capacity';
    }
    return 'Not eligible for guaranteeing loans';
  }

  @override
  @override
  Future<Map<String, dynamic>> getUserLoanStatistics(String userId) async {
    try {
      // Get all user's loans
      final loans = await _firestore
          .collection('loans')
          .where('userId', isEqualTo: userId)
          .get();

      // Get all payments
      final payments = await _firestore
          .collection('loan_payments')
          .where('userId', isEqualTo: userId)
          .get();

      // Get active guarantees
      final activeGuarantees = await _firestore
          .collection('guarantees')
          .where('guarantorId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      // Get defaulted guarantees
      final defaultedGuarantees = await _firestore
          .collection('guarantees')
          .where('guarantorId', isEqualTo: userId)
          .where('status', isEqualTo: 'defaulted')
          .get();

      var totalAmount = 0.0;
      var totalGuaranteed = 0.0;
      var defaultCount = 0;
      var totalDaysLate = 0;
      var latePayments = 0;
      var maxLoanTenure = 0;

      for (final loan in loans.docs) {
        final data = loan.data();
        final amount = (data['amount'] as num).toDouble();
        final tenure = (data['tenureMonths'] as num).toInt();
        
        totalAmount += amount;
        if (data['status'] == 'defaulted') defaultCount++;
        maxLoanTenure = maxLoanTenure > tenure ? maxLoanTenure : tenure;
      }

      // Calculate payment statistics
      for (final payment in payments.docs) {
        final data = payment.data();
        final dueDate = (data['dueDate'] as Timestamp).toDate();
        final paidDate = (data['paidDate'] as Timestamp?)?.toDate();
        
        if (paidDate != null) {
          if (paidDate.isAfter(dueDate.add(Duration(days: 1)))) { // Give 1 day grace period
            final daysLate = paidDate.difference(dueDate).inDays;
            totalDaysLate += daysLate;
            latePayments++;
          }
        } else {
          // If not paid and past due date, count as late
          if (DateTime.now().isAfter(dueDate.add(Duration(days: 1)))) {
            final daysLate = DateTime.now().difference(dueDate).inDays;
            totalDaysLate += daysLate;
            latePayments++;
          }
        }
      }

      // Calculate guarantee totals
      for (final guarantee in activeGuarantees.docs) {
        totalGuaranteed += (guarantee.data()['amount'] as num).toDouble();
      }

      final onTimePayments = payments.docs.length - latePayments;
      final repaymentRate = payments.docs.isEmpty ? 0.0 :
          (onTimePayments / payments.docs.length) * 100;

      // Get active loans with next payment details
      final activeLoans = loans.docs
          .where((doc) => doc.data()['status'] == 'active')
          .map((doc) => doc.data())
          .toList();

      DateTime? nextPaymentDue;
      var totalOutstanding = 0.0;

      for (final loan in activeLoans) {
        totalOutstanding += (loan['remainingAmount'] as num?)?.toDouble() ?? 0.0;
        final nextPayment = loan['nextPaymentDate'] as Timestamp?;
        if (nextPayment != null) {
          final date = nextPayment.toDate();
          if (nextPaymentDue == null || date.isBefore(nextPaymentDue)) {
            nextPaymentDue = date;
          }
        }
      }

      return {
        'summary': {
          'totalLoans': loans.docs.length,
          'totalAmount': totalAmount,
          'repaymentRate': repaymentRate,
          'averageDaysLate': latePayments > 0 ? 
            (totalDaysLate / latePayments) : 0,
          'defaultCount': defaultCount,
        },
        'current': {
          'activeLoans': activeLoans.length,
          'totalOutstanding': totalOutstanding,
          if (nextPaymentDue != null) 'nextPaymentDue': nextPaymentDue.toIso8601String(),
        },
        'history': {
          'completedLoans': loans.docs
              .where((doc) => doc.data()['status'] == 'completed')
              .length,
          'latePayments': latePayments,
          'averageLoanAmount': loans.docs.isEmpty ? 0 : totalAmount / loans.docs.length,
          'longestLoanTenure': maxLoanTenure,
        },
        'guarantees': {
          'activeGuarantees': activeGuarantees.docs.length,
          'totalGuaranteed': totalGuaranteed,
          'defaultedGuarantees': defaultedGuarantees.docs.length,
        }
      };
    } catch (e) {
      throw LoanRolloverException('Error getting user loan statistics: $e');
    }
  }

  @override
  @override
  Future<void> archiveLoan({
    required String loanId,
    required String reason,
    bool archivePayments = true,
    bool archiveDocuments = true,
  }) async {
    try {
      final loanDoc = await _firestore.collection('loans').doc(loanId).get();
      
      if (!loanDoc.exists) {
        throw NotFoundException('Loan not found', code: 'LOAN_NOT_FOUND');
      }

      final status = loanDoc.data()!['status'] as String;
      if (!['completed', 'defaulted'].contains(status)) {
        throw const ValidationException(
          'Only completed or defaulted loans can be archived',
          code: 'INVALID_STATUS'
        );
      }

      // Archive the loan and related data
      await _firestore.runTransaction((transaction) async {
        // 1. Copy loan data to archives
        transaction.set(
          _firestore.collection('archived_loans').doc(loanId),
          {
            ...loanDoc.data()!,
            'archivedAt': FieldValue.serverTimestamp(),
            'archiveReason': reason,
          }
        );

        if (archivePayments) {
          // 2. Get and archive payment history
          final payments = await _firestore
              .collection('loan_payments')
              .where('loanId', isEqualTo: loanId)
              .get();

          for (final payment in payments.docs) {
            transaction.set(
              _firestore.collection('archived_loan_payments').doc(payment.id),
              {
                ...payment.data(),
                'archivedAt': FieldValue.serverTimestamp(),
              }
            );
            transaction.delete(payment.reference);
          }
        }

        if (archiveDocuments) {
          // 3. Get and archive loan documents
          final documents = await _firestore
              .collection('loan_documents')
              .where('loanId', isEqualTo: loanId)
              .get();

          for (final doc in documents.docs) {
            transaction.set(
              _firestore.collection('archived_loan_documents').doc(doc.id),
              {
                ...doc.data(),
                'archivedAt': FieldValue.serverTimestamp(),
              }
            );
            transaction.delete(doc.reference);
          }
        }

        // 4. Delete from active collection
        transaction.delete(loanDoc.reference);
      });

      // Clear from cache
      _loanCache.remove(loanId);
    } catch (e) {
      if (e is LoanException) rethrow;
      throw LoanRolloverException('Error archiving loan: $e');
    }
  }

  /// Private helper method for loan summaries
  Future<Map<String, dynamic>> _getUserLoanSummary({
    required String userId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
    int offset = 0,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      Query query = _firestore.collection('loans')
          .where('userId', isEqualTo: userId);

      // Apply status filter
      if (status != null && status.isNotEmpty) {
        if (!LoanServiceInterface.validLoanStatuses.containsKey(status)) {
          // Can't make const due to string interpolation
        throw ValidationException('Invalid loan status: $status');
        }
        query = query.where('status', isEqualTo: status);
      }

      // Apply date filters
      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Validate sort field
      if (!['createdAt', 'amount', 'dueDate', 'status'].contains(sortBy)) {
        // Can't make const due to string interpolation
      throw ValidationException('Invalid sort field: $sortBy');
      }

      // Apply sorting
      query = query.orderBy(
        sortBy,
        descending: sortOrder.toLowerCase() == 'desc'
      );

      // Get total count
      final total = await query.count().get();

      // Execute query with pagination
      final loans = await query
          .orderBy(FieldPath.documentId) // Secondary sort for consistency
          .limit(limit)
          .get();

      // Skip to offset if needed
      var items = loans.docs;
      if (offset > 0) {
        final lastDoc = loans.docs.last;
        items = (await query
          .orderBy(FieldPath.documentId)
          .startAfterDocument(lastDoc)
          .limit(offset)
          .get()
        ).docs;
      }

      // Calculate page info
      final totalCount = total.count ?? 0;
      final totalPages = (totalCount / limit).ceil();
      final currentPage = (offset / limit).floor() + 1;

      return {
        'items': items.map((doc) {
          final Map<String, dynamic> data = {
            ...(doc.data()! as Map<String, dynamic>),
            'id': doc.id,
          };
          return data;
        }).toList(),
        'total': totalCount,
        'page': currentPage,
        'totalPages': totalPages,
        'hasMore': currentPage < totalPages,
      };
    } catch (e) {
      if (e is LoanException) rethrow;
      throw LoanRolloverException('Error getting loan summary: $e');
    }
  }

  @override
  Future<List<RolloverRequest>> getRolloverHistory(String userId) async {
    try {
      final requests = await _firestore
          .collection('rollover_requests')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return requests.docs.map((doc) => RolloverRequest.fromMap({
        ...doc.data(),
        'id': doc.id,
      })).toList();
    } catch (e) {
      throw LoanRolloverException('Error getting rollover history: $e');
    }
  }

  @override
  Future<List<RolloverRequest>> getPendingRolloverRequests(String guarantorId) async {
    try {
      if (!_approvalRateLimit.checkAndRecord(guarantorId)) {
        throw const LoanRolloverException(
          'Too many approval requests. Please wait a few minutes.'
        );
      }

      final requests = await _firestore
          .collection('rollover_requests')
          .where('status', isEqualTo: 'pending')
          .where('guarantors', arrayContains: guarantorId)
          .orderBy('createdAt', descending: true)
          .get();

      return requests.docs.map((doc) => RolloverRequest.fromMap({
        ...doc.data(),
        'id': doc.id,
      })).toList();
    } catch (e) {
      if (e is LoanException) rethrow;
      throw LoanRolloverException('Error getting pending requests: $e');
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
    try {
      if (!_rolloverRateLimit.checkAndRecord(userId)) {
        throw const LoanRolloverException(
          'Too many rollover requests. Please wait a few minutes.'
        );
      }

      // Check loan eligibility
      final eligibility = await checkRolloverEligibility(oldLoanId);
      if (!eligibility.isEligible) {
        // We can't make this const since it has dynamic message
        throw EligibilityException(
          'Loan not eligible for rollover: ${eligibility.message}'
        );
      }

      // Validate tenure
      final availableTenures = eligibility.availableTenures ?? [];
      if (!availableTenures.contains(newTenureMonths)) {
        // Can't make const due to string interpolation
        throw ValidationException(
          'Invalid tenure. Available options: ${availableTenures.join(", ")} months'
        );
      }

      // Validate amount
      if (newLoanAmount > (eligibility.maxAmount ?? 0)) {
        throw ValidationException(
          'Requested amount exceeds maximum allowed: ${eligibility.maxAmount}'
        );
      }

      // Get current guarantors
      final guarantors = await getLoanGuarantors(oldLoanId);
      if (guarantors.isEmpty) {
        throw const ValidationException('No active guarantors found for the loan');
      }

      // Verify each guarantor is still eligible
      for (final guarantor in guarantors) {
        final eligibility = await checkGuarantorEligibility(
          userId: guarantor.userId,
          loanAmount: newLoanAmount / guarantors.length,
          loanTenure: newTenureMonths,
        );
        if (!eligibility['isEligible']) {
          throw EligibilityException(
            'Guarantor ${guarantor.fullName} is no longer eligible: ${eligibility['reason']}'
          );
        }
      }

      // Create the request
      final requestRef = _firestore.collection('rollover_requests').doc();
      final request = {
        'id': requestRef.id,
        'oldLoanId': oldLoanId,
        'userId': userId,
        'newLoanAmount': newLoanAmount,
        'newTenureMonths': newTenureMonths,
        'guarantors': guarantors.map((g) => g.userId).toList(),
        'status': 'pending',
        'reason': reason,
        'attachments': attachments ?? [],
        'approvals': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: LoanServiceInterface.rolloverRequestExpiryHours))
        ),
        'metadata': {
          'totalGuarantors': guarantors.length,
          'approvalCount': 0,
          'currentAmount': eligibility.requirements?['currentAmount'],
          'amountPaid': eligibility.requirements?['amountPaid'],
          'remainingAmount': eligibility.requirements?['remainingAmount'],
          'borrowerName': (await _firestore.collection('users').doc(userId).get()).data()?['fullName'] ?? 'Unknown',
        }
      };

      await requestRef.set(request);

      if (notifyGuarantors) {
        // Notify guarantors (implemented elsewhere)
        _notifyGuarantors(guarantors, request);
      }

      return RolloverRequest.fromMap(request);
    } catch (e) {
      if (e is LoanException) rethrow;
      throw LoanRolloverException('Error creating rollover request: $e');
    }
  }

  @override
  Future<RolloverRequest> approveRollover({
    required String requestId,
    required String guarantorId,
    String? verificationCode,
    String? comments,
  }) async {
    try {
      if (!_approvalRateLimit.checkAndRecord(guarantorId)) {
        throw const LoanRolloverException(
          'Too many approval attempts. Please wait a few minutes.'
        );
      }

      // Get and validate request
      final requestDoc = await _firestore
          .collection('rollover_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw NotFoundException('Rollover request not found');
      }

      final request = requestDoc.data()!;
      
      // Check request status
      if (request['status'] != 'pending') {
        throw ValidationException(
          'Request is no longer pending. Status: ${request['status']}'
        );
      }

      // Check expiry
      final expiresAt = (request['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        await requestDoc.reference.update({
          'status': 'expired',
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        throw const ValidationException('Request has expired');
      }

      // Verify guarantor is valid for this request
      final guarantors = List<String>.from(request['guarantors']);
      if (!guarantors.contains(guarantorId)) {
        throw const ValidationException('Not a valid guarantor for this request');
      }

      // Check if already approved
      final approvals = List<String>.from(request['approvals'] ?? []);
      if (approvals.contains(guarantorId)) {
                throw const ValidationException('You have already approved this request');
      }

      // Verify OTP if required
      if (verificationCode != null) {
        if (!(await _verifyOTP(guarantorId, verificationCode))) {
          throw const ValidationException('Invalid verification code');
        }
      }

      // Re-check guarantor eligibility
      final newAmount = (request['newLoanAmount'] as num).toDouble();
      final eligibility = await checkGuarantorEligibility(
        userId: guarantorId,
        loanAmount: newAmount / guarantors.length,
        loanTenure: (request['newTenureMonths'] as int),
      );

      if (!eligibility['isEligible']) {
        throw EligibilityException(
          'You are no longer eligible to be a guarantor: ${eligibility['reason']}'
        );
      }

      // Update request with approval
      await requestDoc.reference.update({
        'approvals': FieldValue.arrayUnion([guarantorId]),
        'metadata.approvalCount': FieldValue.increment(1),
        if (comments != null) 'comments.$guarantorId': comments,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Check if all guarantors have approved
      final updatedRequest = await requestDoc.reference.get();
      final updatedApprovals = List<String>.from(updatedRequest.data()!['approvals']);
      
      if (updatedApprovals.length == guarantors.length) {
        // All guarantors have approved, process the rollover
        await _processRollover(requestId);
      }

      return RolloverRequest.fromMap({
        ...updatedRequest.data()!,
        'id': requestId,
      });
    } catch (e) {
      if (e is LoanException) rethrow;
      throw LoanRolloverException('Error approving rollover: $e');
    }
  }

  // Private helper methods

  Future<void> _notifyRolloverCompleted(String requestId) async {
    try {
      final requestDoc = await _firestore
          .collection('rollover_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) return;
      final request = requestDoc.data()!;

      final notifications = _firestore.collection('notifications');
      final userId = request['userId'] as String;
      final guarantors = List<String>.from(request['guarantors']);
      final newLoanId = request['newLoanId'] as String;
      final amount = (request['newLoanAmount'] as num).toDouble();

      // Notify borrower
      await notifications.add({
        'userId': userId,
        'type': 'rollover_completed',
        'title': 'Loan Rollover Completed',
        'message': 'Your loan rollover for \$${amount.toStringAsFixed(2)} has been completed.',
        'data': {
          'requestId': requestId,
          'newLoanId': newLoanId,
          'amount': amount,
        },
        'status': 'unread',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify guarantors
      for (final guarantorId in guarantors) {
        await notifications.add({
          'userId': guarantorId,
          'type': 'rollover_completed',
          'title': 'Loan Rollover Completed',
          'message': 'A loan rollover you guaranteed has been completed.',
          'data': {
            'requestId': requestId,
            'newLoanId': newLoanId,
            'amount': amount,
          },
          'status': 'unread',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Log error but don't throw to avoid disrupting the main flow
      _logger.warning('Error sending rollover completion notifications', e);
    }
  }

  Future<void> _notifyGuarantors(List<LoanGuarantor> guarantors, Map<String, dynamic> request) async {
    try {
      final notifications = _firestore.collection('notifications');
      final borrowerDoc = await _firestore.collection('users').doc(request['userId']).get();
      final borrowerName = borrowerDoc.data()?['fullName'] ?? 'A borrower';
      final amount = (request['newLoanAmount'] as num).toDouble();
      final formattedAmount = amount.toStringAsFixed(2);

      for (final guarantor in guarantors) {
        await notifications.add({
          'userId': guarantor.userId,
          'type': 'rollover_request',
          'title': 'New Loan Rollover Request',
          'message': '$borrowerName has requested you to guarantee their loan rollover of \$$formattedAmount',
          'data': {
            'requestId': request['id'],
            'loanId': request['oldLoanId'],
            'amount': amount,
            'expiresAt': request['expiresAt'],
          },
          'status': 'unread',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Send SMS/Email notifications here if needed
      }
    } catch (e) {
      // Log error but don't throw to avoid disrupting the main flow
      _logger.warning('Error sending guarantor notifications', e);
    }
  }

  Future<bool> _verifyOTP(String userId, String code) async {
    try {
      // Check OTP in Firestore
      final otpDoc = await _firestore
          .collection('otp_verifications')
          .where('userId', isEqualTo: userId)
          .where('code', isEqualTo: code)
          .where('type', isEqualTo: 'rollover_approval')
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .where('used', isEqualTo: false)
          .limit(1)
          .get();

      if (otpDoc.docs.isEmpty) {
        return false;
      }

      // Mark OTP as used
      await otpDoc.docs.first.reference.update({
        'used': true,
        'usedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      _logger.warning('Error verifying OTP', e);
      return false;
    }
  }

  Future<void> _processRollover(String requestId) async {
    try {
      final requestDoc = await _firestore
          .collection('rollover_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw NotFoundException('Rollover request not found');
      }

      final request = requestDoc.data()!;
      final oldLoanId = request['oldLoanId'] as String;
      final userId = request['userId'] as String;
      final newAmount = (request['newLoanAmount'] as num).toDouble();
      final newTenure = request['newTenureMonths'] as int;
      final guarantorIds = List<String>.from(request['guarantors']);

      await _firestore.runTransaction((transaction) async {
        // 1. Get old loan details
        final oldLoanDoc = await transaction.get(
          _firestore.collection('loans').doc(oldLoanId)
        );
        
        if (!oldLoanDoc.exists) {
          throw NotFoundException('Original loan not found');
        }

        final oldLoan = oldLoanDoc.data()!;
        final remainingAmount = (oldLoan['remainingAmount'] as num).toDouble();

        // 2. Create new loan
        final newLoanRef = _firestore.collection('loans').doc();
        final newLoanData = {
          'userId': userId,
          'amount': newAmount,
          'tenureMonths': newTenure,
          'status': 'active',
          'previousLoanId': oldLoanId,
          'rolloverRequestId': requestId,
          'rolloverAmount': remainingAmount,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'remainingAmount': newAmount,
          'amountPaid': 0.0,
        };

        transaction.set(newLoanRef, newLoanData);

        // 3. Update old loan status
        transaction.update(oldLoanDoc.reference, {
          'status': 'rolled_over',
          'rolledOverTo': newLoanRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
          'statusRemarks': 'Rolled over to new loan ${newLoanRef.id}',
        });

        // 4. Create new guarantor records
        final guaranteeAmount = newAmount / guarantorIds.length;
        for (final guarantorId in guarantorIds) {
          final guaranteeRef = _firestore.collection('guarantees').doc();
          transaction.set(guaranteeRef, {
            'loanId': newLoanRef.id,
            'guarantorId': guarantorId,
            'amount': guaranteeAmount,
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // 5. Update request status
        transaction.update(requestDoc.reference, {
          'status': 'completed',
          'newLoanId': newLoanRef.id,
          'completedAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // 6. Clear old guarantees
        final oldGuarantees = await _firestore
            .collection('guarantees')
            .where('loanId', isEqualTo: oldLoanId)
            .get();

        for (final doc in oldGuarantees.docs) {
          transaction.update(doc.reference, {
            'status': 'transferred',
            'transferredToLoanId': newLoanRef.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Clear cache entries
      _loanCache.remove(oldLoanId);

      // Notify all parties (async)
      _notifyRolloverCompleted(requestId);
    } catch (e) {
      if (e is LoanException) rethrow;
      throw LoanRolloverException('Error processing rollover: $e');
    }
  }
}
