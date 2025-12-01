import 'package:flutter/foundation.dart';
import '../../features/dashboard/data/services/dashboard_service.dart';
import '../../features/dashboard/domain/models/dashboard_data.dart';
import '../../features/dashboard/domain/models/enums.dart';
import '../models/money.dart';

class DashboardProvider with ChangeNotifier {
  final DashboardService _service;
  
  DashboardData? _dashboardData;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;

  DashboardProvider(this._service) {
    // Load initial data
    loadDashboard();
  }

  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;

  // Computed getters for convenient access
  Money get balance => _dashboardData?.balance ?? Money.zero;
  Money get savingsTotal => _dashboardData?.savingsTotal ?? Money.zero;
  Money get investmentsTotal => _dashboardData?.investmentsTotal ?? Money.zero;
  Money get loansTotal => _dashboardData?.loansTotal ?? Money.zero;
  List<TransactionSummary> get recentTransactions => _dashboardData?.recentTransactions ?? [];
  List<Investment> get activeInvestments => _dashboardData?.activeInvestments ?? [];
  List<Loan> get activeLoans => _dashboardData?.activeLoans ?? [];
  AccountStatistics get statistics => _dashboardData?.statistics ?? AccountStatistics.empty();

  Future<void> loadDashboard({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    if (!forceRefresh) notifyListeners();

    if (forceRefresh) {
      _isRefreshing = true;
      notifyListeners();
    }

    try {
      final newData = await _service.getDashboardData(forceRefresh: forceRefresh);
      _dashboardData = newData as DashboardData?;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading dashboard: $e');
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadDashboard(forceRefresh: true);

  // Filter transactions by type
  List<TransactionSummary> getTransactionsByType(TransactionType type) {
    return recentTransactions.where((t) => t.type == type).toList();
  }

  // Get investments by status
  List<Investment> getInvestmentsByStatus(InvestmentStatus status) {
    return activeInvestments.where((i) => i.status == status).toList();
  }

  // Get loans by status
  List<Loan> getLoansByStatus(LoanStatus status) {
    return activeLoans.where((l) => l.status == status).toList();
  }

  // Calculate total returns from investments
  Money get totalInvestmentReturns {
    return activeInvestments.fold(
      Money.zero,
      (Money sum, investment) => sum + investment.returns
    );
  }

  // Calculate total loan balance
  Money get totalLoanBalance {
    return activeLoans.fold(
      Money.zero,
      (Money sum, loan) => sum + loan.balance
    );
  }

  // Check if user has any active investments
  bool get hasActiveInvestments => activeInvestments.isNotEmpty;

  // Check if user has any active loans
  bool get hasActiveLoans => activeLoans.isNotEmpty;

  // Get number of transactions by type
  int getTransactionCountByType(TransactionType type) {
    return recentTransactions.where((t) => t.type == type).length;
  }

  // Calculate total amount by transaction type
  Money getTransactionTotalByType(TransactionType type) {
    return recentTransactions
        .where((t) => t.type == type)
        .fold(Money.zero, (Money sum, t) => sum + t.amount);
  }

  // Get number of investments by status
  int getInvestmentCountByStatus(InvestmentStatus status) {
    return activeInvestments.where((i) => i.status == status).length;
  }

  // Get total amount of investments by status
  Money getInvestmentTotalByStatus(InvestmentStatus status) {
    return activeInvestments
        .where((i) => i.status == status)
        .fold(Money.zero, (Money sum, i) => sum + i.amount);
  }

  // Get number of loans by status
  int getLoanCountByStatus(LoanStatus status) {
    return activeLoans.where((l) => l.status == status).length;
  }

  // Get total amount of loans by status
  Money getLoanTotalByStatus(LoanStatus status) {
    return activeLoans
        .where((l) => l.status == status)
        .fold(Money.zero, (Money sum, l) => sum + l.amount);
  }
}
