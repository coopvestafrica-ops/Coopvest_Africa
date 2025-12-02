import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/exceptions/api_exception.dart';
import '../../../../core/utils/api_utils.dart';
import '../models/loan_status.dart';
import '../models/loan_guarantor.dart';
import '../services/loan_service.dart';
import '../models/loan_service_interface.dart';

enum LoanUpdateType { status, guarantor, payment, rollover }

class LoanStatusProvider extends ChangeNotifier {
  final LoanService _loanService;

  LoanStatus? _loanStatus;
  List<LoanGuarantor> _guarantors = [];
  bool _isLoading = false;
  String? _error;
  String? _errorCode;
  Map<String, dynamic>? _errorData;
  final Map<String, bool> _refreshingGuarantors = {};
  String? _currentLoanId;
  StreamController<LoanUpdateType>? _updateStreamController;
  Timer? _autoRefreshTimer;

  // Cache and refresh configuration
  static const _statusCacheDuration = Duration(minutes: 5);
  static const _autoRefreshInterval = Duration(minutes: 2);
  static const _maxRetryAttempts = 5;
  static const _baseRetryDelay = Duration(seconds: 1);
  static const _maxRetryDelay = Duration(minutes: 1);

  DateTime? _lastStatusCheck;
  int _retryCount = 0;
  bool _isAutoRefreshEnabled = false;
  bool _isTransactionInProgress = false;

  LoanStatusProvider(this._loanService) {
    _updateStreamController = StreamController<LoanUpdateType>.broadcast();
  }

  // Getters
  LoanStatus? get loanStatus => _loanStatus;
  List<LoanGuarantor> get guarantors => _guarantors;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorCode => _errorCode;
  Map<String, dynamic>? get errorData => _errorData;
  bool get hasError => _error != null;
  Stream<LoanUpdateType> get updates => _updateStreamController!.stream;
  bool get isAutoRefreshEnabled => _isAutoRefreshEnabled;
  bool isGuarantorRefreshing(String guarantorId) =>
      _refreshingGuarantors[guarantorId] ?? false;

  // Computed properties
  bool get hasGuarantors => _guarantors.isNotEmpty;
  int get guarantorCount => _guarantors.length;
  bool get isPending => _loanStatus?.status.toLowerCase() == 'pending';
  bool get isActive => _loanStatus?.status.toLowerCase() == 'active';
  bool get isCompleted => _loanStatus?.status.toLowerCase() == 'completed';
  bool get isDefaulted => _loanStatus?.status.toLowerCase() == 'defaulted';
  bool get isCancelled => _loanStatus?.status.toLowerCase() == 'cancelled';
  bool get isRejected => _loanStatus?.status.toLowerCase() == 'rejected';
  bool get isRolledOver => _loanStatus?.status.toLowerCase() == 'rolled_over';
  double get completionPercentage =>
      _loanStatus?.completionPercentage.toDouble() ?? 0.0;
  String? get currentLoanId => _currentLoanId;
  bool get shouldRefreshStatus =>
      _lastStatusCheck == null ||
      DateTime.now().difference(_lastStatusCheck!) > _statusCacheDuration;

  Future<ApiResponse<LoanStatus>> loadLoanStatus(
    String loanId, {
    bool forceRefresh = false,
    bool enableAutoRefresh = false,
  }) async {
    if (_isLoading) {
      return ApiResponse.error(error: 'A request is already in progress');
    }
    if (!forceRefresh && !shouldRefreshStatus && _isCurrentLoan(loanId)) {
      return ApiResponse.success(_loanStatus!);
    }

    try {
      _setLoading(true, loanId);

      final response = await _retryOnFailure(() => _loanService.getLoanDetails(
            loanId: loanId,
            includeGuarantors: true,
            useCache: !forceRefresh,
          ));

      if (!_isCurrentLoan(loanId)) {
        return ApiResponse.error(error: 'Loan ID mismatch');
      }

      final newStatus = LoanStatus.fromJson(response);
      _updateLoanStatus(newStatus, response);

      if (enableAutoRefresh && !_isAutoRefreshEnabled) {
        _startAutoRefresh();
      } else if (!enableAutoRefresh && _isAutoRefreshEnabled) {
        _stopAutoRefresh();
      }

      return ApiResponse.success(newStatus);
    } catch (e) {
      if (!_isCurrentLoan(loanId)) {
        return ApiResponse.error(error: 'Loan ID mismatch');
      }

      final error = _handleError(e);
      _clearLoanStatus();

      return ApiResponse.error(
        error: error.message,
        errorCode: error.errorCode ?? 'UNKNOWN_ERROR',
        errorData: error.errorData,
        retryAfter: error.retryAfter,
      );
    } finally {
      if (_isCurrentLoan(loanId)) {
        _setLoading(false);
      }
    }
  }

  Future<ApiResponse<LoanGuarantor>> refreshGuarantor(
      String loanId, String guarantorId) async {
    if (_refreshingGuarantors[guarantorId] == true) {
      return ApiResponse.error(error: 'Guarantor refresh already in progress');
    }
    if (_currentLoanId != loanId) {
      return ApiResponse.error(error: 'Loan ID mismatch');
    }

    try {
      _refreshingGuarantors[guarantorId] = true;
      notifyListeners();

      final guarantorDetails =
          await _retryOnFailure(() => _loanService.checkGuarantorEligibility(
                userId: guarantorId,
                loanAmount: _loanStatus?.totalAmount ?? 0,
                loanTenure: _loanStatus?.additionalInfo?['tenure_months'] ?? 12,
              ));

      if (!_isCurrentLoan(loanId)) {
        return ApiResponse.error(error: 'Loan ID mismatch');
      }

      final index = _guarantors.indexWhere((g) => g.id == guarantorId);
      if (index == -1) {
        return ApiResponse.error(error: 'Guarantor not found');
      }

      final updatedGuarantor = _guarantors[index].copyWith(
        isEligible: guarantorDetails['isEligible'] ?? false,
        maxAmount: guarantorDetails['maxAmount']?.toDouble(),
        metrics: guarantorDetails['metrics'],
        lastValidated: DateTime.now(),
        validationAttempts: _guarantors[index].validationAttempts + 1,
      );

      _guarantors = List.from(_guarantors)..[index] = updatedGuarantor;
      _updateStreamController?.add(LoanUpdateType.guarantor);

      return ApiResponse.success(updatedGuarantor);
    } catch (e) {
      if (!_isCurrentLoan(loanId)) {
        return ApiResponse.error(error: 'Loan ID mismatch');
      }

      final error = _handleError(e);
      return ApiResponse.error(
        error: error.message,
        errorCode: error.errorCode ?? 'UNKNOWN_ERROR',
        errorData: error.errorData,
        retryAfter: error.retryAfter,
      );
    } finally {
      if (_isCurrentLoan(loanId)) {
        _refreshingGuarantors[guarantorId] = false;
        notifyListeners();
      }
    }
  }

  ApiResponse<bool> canAddMoreGuarantors() {
    if (_loanStatus == null) {
      return ApiResponse.error(error: 'No active loan status');
    }

    // Check against the maximum allowed guarantors
    if (guarantorCount >= LoanServiceInterface.maxActiveGuarantees) {
      return ApiResponse.error(
        error: 'Maximum number of guarantors reached',
        errorCode: 'MAX_GUARANTORS_REACHED',
        errorData: {
          'current': guarantorCount,
          'maximum': LoanServiceInterface.maxActiveGuarantees,
        },
      );
    }

    // Only allow adding guarantors in valid states
    final status = _loanStatus?.status.toLowerCase();
    final canAdd = status == 'pending' || status == 'active';

    if (!canAdd) {
      return ApiResponse.error(
        error: 'Cannot add guarantors in current loan state',
        errorCode: 'INVALID_LOAN_STATE',
        errorData: {'currentState': status},
      );
    }

    return ApiResponse.success(true);
  }

  Future<ApiResponse<LoanStatus>> refreshStatus(
      {bool enableAutoRefresh = false}) async {
    if (_currentLoanId == null) {
      return ApiResponse.error(error: 'No active loan to refresh');
    }
    return loadLoanStatus(_currentLoanId!,
        forceRefresh: true, enableAutoRefresh: enableAutoRefresh);
  }

  void enableAutoRefresh() {
    if (!_isAutoRefreshEnabled) {
      _startAutoRefresh();
    }
  }

  void disableAutoRefresh() {
    if (_isAutoRefreshEnabled) {
      _stopAutoRefresh();
    }
  }

  Future<T> _retryOnFailure<T>(Future<T> Function() operation) async {
    _retryCount = 0;
    ApiException? lastError;

    while (_retryCount < _maxRetryAttempts) {
      try {
        return await operation();
      } catch (e) {
        _retryCount++;

        // Don't retry if it's a non-retryable API exception
        if (e is ApiException) {
          if (!e.isRetryable) rethrow;
          lastError = e;
        }

        // Don't retry if we've hit the max attempts
        if (_retryCount >= _maxRetryAttempts) {
          throw lastError ??
              ApiException(
                'Operation failed after $_maxRetryAttempts attempts',
                errorData: {
                  'code': 'MAX_RETRIES_EXCEEDED',
                  'statusCode': 500,
                  'attempts': _maxRetryAttempts,
                  'lastError': lastError?.toString(),
                },
              );
        }

        // Calculate exponential backoff with jitter
        final baseDelay =
            _baseRetryDelay.inMilliseconds * (1 << (_retryCount - 1));
        final jitter = (DateTime.now().millisecondsSinceEpoch % 1000) / 1000.0;
        final delay = Duration(
          milliseconds: (baseDelay * (1 + jitter))
              .clamp(0, _maxRetryDelay.inMilliseconds)
              .toInt(),
        );

        await Future.delayed(delay);
      }
    }

    throw ApiException('Unexpected error in retry loop');
  }

  void _updateLoanStatus(LoanStatus newStatus, Map<String, dynamic> response) {
    if (_isTransactionInProgress) {
      throw StateError('Another state update is in progress');
    }

    try {
      _isTransactionInProgress = true;

      // Create new guarantor list first to ensure it's valid
      final newGuarantors = (response['guarantors'] as List? ?? [])
          .map((g) => LoanGuarantor.fromJson(g))
          .toList();

      // Then update all state atomically
      _loanStatus = newStatus;
      _guarantors = newGuarantors;
      _error = null;
      _errorCode = null;
      _errorData = null;
      _lastStatusCheck = DateTime.now();

      // Notify of changes
      _updateStreamController?.add(LoanUpdateType.status);
      notifyListeners();
    } finally {
      _isTransactionInProgress = false;
    }
  }

  void _clearLoanStatus() {
    if (_isTransactionInProgress) {
      throw StateError('Another state update is in progress');
    }

    try {
      _isTransactionInProgress = true;

      _loanStatus = null;
      _guarantors = [];
      _lastStatusCheck = null;
      _error = null;
      _errorCode = null;
      _errorData = null;

      notifyListeners();
    } finally {
      _isTransactionInProgress = false;
    }
  }

  void _setLoading(bool loading, [String? newLoanId]) {
    if (_isTransactionInProgress) {
      throw StateError('Another state update is in progress');
    }

    try {
      _isTransactionInProgress = true;

      _isLoading = loading;
      if (newLoanId != null) {
        _currentLoanId = newLoanId;
      }

      notifyListeners();
    } finally {
      _isTransactionInProgress = false;
    }
  }

  ApiException _handleError(dynamic error) {
    if (error is ApiException) {
      _error = error.message;
      _errorCode = error.errorCode;
      _errorData = error.errorData;
      return error;
    } else {
      _error = error.toString();
      _errorCode = 'UNKNOWN_ERROR';
      _errorData = {
        'code': 'UNKNOWN_ERROR',
        'statusCode': 500,
      };
      return ApiException(
        error.toString(),
        errorData: _errorData,
      );
    }
  }

  void _startAutoRefresh() {
    if (_currentLoanId == null) return;

    _autoRefreshTimer?.cancel();
    _retryCount = 0;

    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (timer) async {
      // Skip if another operation is in progress
      if (_isLoading || _isTransactionInProgress) return;

      try {
        await refreshStatus();
        _retryCount = 0; // Reset retry count on success
      } catch (e) {
        _retryCount++;

        // If we've failed too many times, disable auto-refresh
        if (_retryCount >= _maxRetryAttempts) {
          _stopAutoRefresh();
          // Notify listeners of the auto-refresh failure
          _error = 'Auto-refresh disabled due to repeated failures';
          _errorCode = 'AUTO_REFRESH_FAILED';
          _errorData = {
            'code': 'AUTO_REFRESH_FAILED',
            'statusCode': 500,
            'attempts': _retryCount,
            'lastError': e.toString(),
          };
          notifyListeners();
        }
      }
    });

    _isAutoRefreshEnabled = true;
    notifyListeners();
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    _isAutoRefreshEnabled = false;
    notifyListeners();
  }

  bool _isCurrentLoan(String loanId) => _currentLoanId == loanId;

  @override
  void dispose() {
    if (_isTransactionInProgress) {
      // Log warning about disposal during transaction
      debugPrint('Warning: LoanStatusProvider disposed during transaction');
    }

    _stopAutoRefresh();
    _updateStreamController?.close();

    try {
      _isTransactionInProgress = true;
      _clearLoanStatus();
      _error = null;
      _errorCode = null;
      _errorData = null;
      _refreshingGuarantors.clear();
      _currentLoanId = null;
    } finally {
      _isTransactionInProgress = false;
    }

    super.dispose();
  }
}
