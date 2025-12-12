import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/money.dart';
import '../../data/models/dashboard_data.dart';
import '../../data/services/dashboard_service.dart';

class DashboardProvider with ChangeNotifier {
  final DashboardService _service;
  final SharedPreferences _prefs;
  DashboardData? _dashboardData;
  String? _error;
  bool _isLoading = false;
  Timer? _autoRefreshTimer;

  bool _isOffline = false;
  DateTime? _lastUpdateTime;
  static const _maxOfflineAge = Duration(hours: 1);
  
  DashboardProvider(this._service, this._prefs) {
    // Load cached data if available
    _loadCachedData();
    _loadLastUpdateTime();
    // Set up initial refresh timer
    _updateRefreshTimer();
  }

  // Getters for dashboard state
  DashboardData? get dashboardData => _dashboardData;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  bool get hasActiveLoan => !loanOverview.activeLoanAmount.isZero;
  bool get canApplyForLoan => loanOverview.isEligibleForNew;
  bool get needsRefresh => _lastUpdateTime == null || 
      DateTime.now().difference(_lastUpdateTime!) > const Duration(minutes: 15);
  bool get isDataStale => _lastUpdateTime == null || 
      DateTime.now().difference(_lastUpdateTime!) > _maxOfflineAge;

  // Overview getters with default values
  WalletOverview get walletOverview => _dashboardData?.walletOverview ?? WalletOverview(
        balance: Money.zero,
        pendingCredit: Money.zero,
        pendingDebit: Money.zero,
      );

  SavingsOverview get savingsOverview => _dashboardData?.savingsOverview ?? SavingsOverview(
        totalSavings: Money.zero,
        monthlyTarget: Money.zero,
        monthlyProgress: 0,
        yearlyTarget: Money.zero,
        yearlyProgress: 0,
        interestEarned: Money.zero,
        expectedInterest: Money.zero,
        goals: const [],
        lastContributionDate: DateTime.now(),
      );

  LoanOverview get loanOverview => _dashboardData?.loanOverview ?? LoanOverview(
        activeLoanAmount: Money.zero,
        totalRepaid: Money.zero,
        nextRepaymentAmount: Money.zero,
        totalLoansReceived: Money.zero,
        isEligibleForNew: false,
        maximumEligibleAmount: Money.zero,
      );

  InvestmentOverview get investmentOverview => _dashboardData?.investmentOverview ?? InvestmentOverview(
        totalInvested: Money.zero,
        currentValue: Money.zero,
        totalReturns: Money.zero,
        pendingReturns: Money.zero,
        activeInvestments: const [],
        portfolioAllocation: const {},
        monthlyReturns: const [],
        lastValuationDate: DateTime.now(),
      );

  List<Transaction> get recentTransactions => _dashboardData?.recentTransactions ?? [];
  List<GuarantorshipOverview> get guarantorships => _dashboardData?.guarantorships ?? [];
  
  // Statistics getters
  double get savingsProgress => savingsOverview.monthlyProgress;
  double get loanUtilization => hasActiveLoan ? 
      loanOverview.totalRepaid.inNaira / (loanOverview.activeLoanAmount + loanOverview.totalRepaid).inNaira : 0.0;
  double get investmentReturn => !investmentOverview.totalInvested.isZero ? 
      (investmentOverview.currentValue - investmentOverview.totalInvested).inNaira / investmentOverview.totalInvested.inNaira : 0.0;

  // Private methods
  bool _checkSignificantChanges(DashboardData? oldData, DashboardData newData) {
    if (oldData == null) return true;

    // Check for significant balance changes (>1%)
    final oldBalance = oldData.walletOverview.balance;
    final newBalance = newData.walletOverview.balance;
    if (!oldBalance.isZero && ((newBalance - oldBalance).inNaira / oldBalance.inNaira).abs() > 0.01) {
      return true;
    }

    // Check for loan status changes
    if (oldData.loanOverview.isEligibleForNew != newData.loanOverview.isEligibleForNew ||
        oldData.loanOverview.activeLoanAmount != newData.loanOverview.activeLoanAmount) {
      return true;
    }

    // Check for new transactions
    if (oldData.recentTransactions.isEmpty && newData.recentTransactions.isNotEmpty) {
      return true;
    }
    
    if (oldData.recentTransactions.isNotEmpty && newData.recentTransactions.isNotEmpty &&
        oldData.recentTransactions.first != newData.recentTransactions.first) {
      return true;
    }

    return false;
  }

  void _updateRefreshTimer() {
    _autoRefreshTimer?.cancel();
    
    // If there's an active loan, check more frequently
    final refreshInterval = hasActiveLoan ? 
        const Duration(minutes: 3) : 
        const Duration(minutes: 5);
    
    _autoRefreshTimer = Timer.periodic(refreshInterval, (_) {
      refreshDashboard();
    });
  }
  Future<void> _loadCachedData() async {
    final cachedJson = _prefs.getString('dashboard_data');
    if (cachedJson != null) {
      try {
        _dashboardData = DashboardData.fromJson(jsonDecode(cachedJson));
        notifyListeners();
      } catch (e) {
        // If cache is corrupted, ignore and proceed to fetch fresh data
        debugPrint('Error loading cached data: $e');
      }
    }
  }

  Future<void> _loadLastUpdateTime() async {
    final timestamp = _prefs.getInt('last_update');
    if (timestamp != null) {
      _lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
  }

  void _handleOfflineState(bool isOffline) {
    if (_isOffline != isOffline) {
      _isOffline = isOffline;
      if (!isOffline) {
        // When coming back online, refresh data if it's stale
        if (needsRefresh) {
          refreshDashboard();
        }
      }
      notifyListeners();
    }
  }

  // Public methods
  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_isOffline && !isDataStale && !forceRefresh) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final data = await _service.getDashboardData(forceRefresh: forceRefresh);
      
      // Compare with previous data to check for significant changes
      final hasSignificantChanges = _checkSignificantChanges(_dashboardData, data);
      
      _dashboardData = data;
      _error = null;
      _isOffline = false;
      _lastUpdateTime = DateTime.now();
      
      // Cache the new data
      await Future.wait([
        _prefs.setString('dashboard_data', jsonEncode(data)),
        _prefs.setInt('last_update', _lastUpdateTime!.millisecondsSinceEpoch),
      ]);
      
      // If there are significant changes, update the refresh timer
      if (hasSignificantChanges) {
        _updateRefreshTimer();
      }
    } catch (e) {
      _error = 'Failed to load dashboard data: ${e.toString()}';
      debugPrint('Error loading dashboard data: $e');
      _handleOfflineState(true);
      
      // Check if we have valid cached data
      if (_dashboardData == null || isDataStale) {
        _error = 'No recent data available. Please check your connection.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboardData(forceRefresh: true);
    
    // Reset offline state and check connectivity
    _handleOfflineState(false);
    await _checkConnectivity();
  }

  Future<bool> _checkConnectivity() async {
    try {
      // Try to make a lightweight request to check connectivity
      final result = await _service.checkConnectivity();
      _handleOfflineState(!result);
      return result;
    } catch (e) {
      _handleOfflineState(true);
      return false;
    }
  }

  Future<void> applyForLoan({
    required Money amount,
    required String purpose,
    required int termMonths,
  }) async {
    if (!canApplyForLoan) {
      throw 'You are not eligible for a new loan at this time';
    }

    if (amount > loanOverview.maximumEligibleAmount) {
      throw 'Amount exceeds maximum eligible amount';
    }

    try {
      await _service.applyForLoan(
        amount: amount,
        purpose: purpose,
        termMonths: termMonths,
      );
      await refreshDashboard();
    } catch (e) {
      debugPrint('Error applying for loan: $e');
      rethrow;
    }
  }

  Future<void> rolloverLoan(int additionalMonths) async {
    if (!hasActiveLoan) {
      throw 'No active loan to rollover';
    }

    try {
      await _service.rolloverLoan(additionalMonths);
      await refreshDashboard();
    } catch (e) {
      debugPrint('Error rolling over loan: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
