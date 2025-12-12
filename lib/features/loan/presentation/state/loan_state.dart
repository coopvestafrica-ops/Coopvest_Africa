import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/loan_service_interface.dart';
import '../../domain/models/loan_application.dart';
import '../../domain/models/loan_guarantor.dart';
import '../../domain/models/rollover_request.dart';
import '../../domain/models/rollover_eligibility.dart';
import '../../../../core/models/loan/loan_application_status.dart';

class LoanState extends ChangeNotifier {
  final LoanServiceInterface _loanService;
  final SharedPreferences _prefs;
  static const _selectedLoanTypeKey = 'selectedLoanType';
  
  LoanState({
    required LoanServiceInterface loanService,
    required SharedPreferences prefs,
  }) : _loanService = loanService,
       _prefs = prefs {
    _loadSavedPreferences();
    _loadCurrentLoan();
  }

  String _selectedLoanType = 'Quick Loan';
  String get selectedLoanType => _selectedLoanType;

  LoanApplicationStatus _status = LoanApplicationStatus.initial;
  LoanApplicationStatus get status => _status;

  String? _loanId;
  String? get loanId => _loanId;

  String? _rejectionReason;
  String? get rejectionReason => _rejectionReason;

  LoanApplication? _currentLoan;
  LoanApplication? get currentLoan => _currentLoan;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  RolloverEligibility? _rolloverEligibility;
  RolloverEligibility? get rolloverEligibility => _rolloverEligibility;

  List<LoanApplication> _loanHistory = [];
  List<LoanApplication> get loanHistory => List.unmodifiable(_loanHistory);

  void _loadSavedPreferences() {
    _selectedLoanType = _prefs.getString(_selectedLoanTypeKey) ?? 'Quick Loan';
    notifyListeners();
  }

  List<LoanGuarantor> _guarantors = [];
  List<LoanGuarantor> get guarantors => List.unmodifiable(_guarantors);

  void setSelectedLoanType(String type) {
    _selectedLoanType = type;
    _prefs.setString(_selectedLoanTypeKey, type);
    notifyListeners();
  }

  Future<void> submitLoanApplication({
    required String userId,
    required double loanAmount,
    required String purpose,
    required double monthlySavings,
    required int tenureMonths,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _status = LoanApplicationStatus.submitting;
      notifyListeners();

      final application = LoanApplication(
        userId: userId,
        type: _selectedLoanType,
        loanAmount: loanAmount,
        tenureMonths: tenureMonths,
        purpose: purpose,
        monthlySavings: monthlySavings,
      );

      final result = await _loanService.submitLoanApplication(application);
      _loanId = result.loanId;
      _currentLoan = await _loanService.getLoanById(result.loanId);
      _status = LoanApplicationStatus.pending;
      
      // Refresh loan history
      await _loadLoanHistory();
    } catch (e) {
      _status = LoanApplicationStatus.initial;
      _errorMessage = 'Failed to submit loan application: $e';
      _currentLoan = null;
      _loanId = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<RolloverRequest> processRollover({
    required String oldLoanId,
    required String userId,
    required double newAmount,
    required int tenureMonths,
  }) async {
    try {
      final result = await _loanService.createRolloverRequest(
        oldLoanId: oldLoanId,
        userId: userId,
        newLoanAmount: newAmount,
        newTenureMonths: tenureMonths,
      );

      // Get current guarantors for the loan
      _guarantors = await _loanService.getLoanGuarantors(oldLoanId);
      notifyListeners();
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> checkRolloverEligibility(String loanId) async {
    try {
      _rolloverEligibility = await _loanService.checkRolloverEligibility(loanId);
      notifyListeners();
    } catch (e) {
      _rolloverEligibility = null;
      notifyListeners();
      rethrow;
    }
  }

  // Only for demo purposes
  Future<void> _loadCurrentLoan() async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_loanId != null) {
        _currentLoan = await _loanService.getLoanById(_loanId!);
        // Convert string status to enum
        if (_currentLoan?.status != null) {
          _status = LoanApplicationStatus.values.firstWhere(
            (s) => s.toString().split('.').last == _currentLoan!.status!,
            orElse: () => LoanApplicationStatus.initial,
          );
        } else {
          _status = LoanApplicationStatus.initial;
        }
      }

      await _loadLoanHistory();
    } catch (e) {
      _errorMessage = 'Failed to load loan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLoanHistory() async {
    try {
      _loanHistory = await _loanService.getLoanHistory();
    } catch (e) {
      _errorMessage = 'Failed to load loan history: $e';
    }
    notifyListeners();
  }

  Future<void> cancelLoan(String loanId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _loanService.cancelLoan(loanId);
      _status = LoanApplicationStatus.cancelled;
      await _loadCurrentLoan();
    } catch (e) {
      _errorMessage = 'Failed to cancel loan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void simulateStaffReview({required bool approve, String? reason}) {
    if (approve) {
      _status = LoanApplicationStatus.active;
      _rejectionReason = null;
    } else {
      _status = LoanApplicationStatus.rejected;
      _rejectionReason = reason ?? 'Not eligible or incomplete requirements.';
    }
    notifyListeners();
  }

  Future<void> refreshLoanStatus() async {
    await _loadCurrentLoan();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
