import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/money.dart';
import '../../../../core/services/api_service.dart';
import '../models/dashboard_data.dart';

class DashboardService {
  final ApiService _apiService;
  static const String _cacheDurationKey = 'dashboard_cache_duration';
  static const String _dashboardCacheKey = 'dashboard_data_cache';
  static const Duration _maxCacheAge = Duration(minutes: 5);

  DashboardService(this._apiService);

  Future<DashboardData> getDashboardData({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedData = await _getCachedDashboardData();
      if (cachedData != null) {
        return cachedData;
      }
    }

    try {
      // Fetch data in parallel for better performance
      final results = await Future.wait([
        _apiService.getWalletBalance(),
        _apiService.getWalletTransactions(page: 1),
        _apiService.getLoans(),
        _apiService.getContributions(),
        _apiService.getInvestments(),
      ]);

      final dashboardData = {
        'wallet': results[0],
        'transactions': results[1],
        'loan': _processLoanData(results[2] as List),
        'savings': _processSavingsData(results[3] as List),
        'investment': _processInvestmentData(results[4] as List),
        'guarantorships': await _fetchGuarantorships(),
      };

      // Cache the dashboard data
      await _cacheDashboardData(dashboardData);

      return DashboardData.fromJson(dashboardData);
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      rethrow;
    }
  }

  Future<DashboardData?> _getCachedDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt(_cacheDurationKey) ?? 0,
      );

      if (DateTime.now().difference(lastUpdateTime) > _maxCacheAge) {
        return null;
      }

      final cachedData = prefs.getString(_dashboardCacheKey);
      if (cachedData == null) {
        return null;
      }

      return compute(_parseDashboardData, cachedData);
    } catch (e) {
      debugPrint('Error reading cached dashboard data: $e');
      return null;
    }
  }

  Future<void> _cacheDashboardData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_cacheDurationKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setString(_dashboardCacheKey, data.toString());
    } catch (e) {
      debugPrint('Error caching dashboard data: $e');
    }
  }

  Map<String, dynamic> _processLoanData(List<dynamic> loans) {
    var activeLoanAmount = Money.zero;
    var totalRepaid = Money.zero;
    DateTime? nextRepaymentDate;
    var nextRepaymentAmount = Money.zero;
    var totalLoansReceived = Money.zero;

    for (final loan in loans) {
      if (loan['status'] == 'active') {
        activeLoanAmount += Money.fromKobo(((loan['remaining_amount'] as num) * 100).round());
        if (nextRepaymentDate == null ||
            DateTime.parse(loan['next_repayment_date']).isBefore(nextRepaymentDate)) {
          nextRepaymentDate = DateTime.parse(loan['next_repayment_date']);
          nextRepaymentAmount = Money.fromKobo(((loan['next_repayment_amount'] as num) * 100).round());
        }
      }
      totalRepaid += Money.fromKobo(((loan['amount_repaid'] as num) * 100).round());
      totalLoansReceived += Money.fromKobo(((loan['amount'] as num) * 100).round());
    }

    return {
      'active_loan_amount': {'amountInKobo': activeLoanAmount.amountInKobo},
      'total_repaid': {'amountInKobo': totalRepaid.amountInKobo},
      'next_repayment_date': nextRepaymentDate?.toIso8601String(),
      'next_repayment_amount': {'amountInKobo': nextRepaymentAmount.amountInKobo},
      'total_loans_received': {'amountInKobo': totalLoansReceived.amountInKobo},
      'is_eligible_for_new': activeLoanAmount.isZero,
      'maximum_eligible_amount': {'amountInKobo': _calculateMaximumEligibleAmount(totalLoansReceived.inNaira, totalRepaid.inNaira) * 100},
    };
  }

  double _calculateMaximumEligibleAmount(double totalLoansReceived, double totalRepaid) {
    // Implement your loan eligibility calculation logic here
    if (totalLoansReceived == 0) return 100000; // Starting amount for new members
    double repaymentRatio = totalRepaid / totalLoansReceived;
    double baseAmount = 100000;
    
    if (repaymentRatio >= 1) {
      baseAmount = totalLoansReceived * 1.5; // 50% increase for good repayment history
    }
    
    return baseAmount.clamp(100000, 5000000); // Min 100k, Max 5M
  }

  Map<String, dynamic> _processSavingsData(List<dynamic> contributions) {
    var totalSavings = Money.zero;
    var monthlyProgress = Money.zero;
    var yearlyProgress = Money.zero;
    var interestEarned = Money.zero;

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final currentYear = DateTime(now.year);

    for (final contribution in contributions) {
      final date = DateTime.parse(contribution['date']);
      final amount = Money.fromKobo(((contribution['amount'] as num) * 100).round());

      totalSavings += amount;

      if (date.isAfter(currentMonth)) {
        monthlyProgress += amount;
      }

      if (date.isAfter(currentYear)) {
        yearlyProgress += amount;
      }

      interestEarned += Money.fromKobo(((contribution['interest'] as num?)?.toDouble() ?? 0 * 100).round());
    }

    // You would typically get these targets from user preferences or business rules
    final monthlyTarget = Money.fromNaira(50000); // Example value
    final yearlyTarget = Money.fromNaira(600000); // Example value

    return {
      'total_savings': {'amountInKobo': totalSavings.amountInKobo},
      'monthly_target': {'amountInKobo': monthlyTarget.amountInKobo},
      'monthly_progress': {'amountInKobo': monthlyProgress.amountInKobo},
      'yearly_target': {'amountInKobo': yearlyTarget.amountInKobo},
      'yearly_progress': {'amountInKobo': yearlyProgress.amountInKobo},
      'interest_earned': {'amountInKobo': interestEarned.amountInKobo},
    };
  }

  Map<String, dynamic> _processInvestmentData(List<dynamic> investments) {
    var totalInvested = Money.zero;
    var currentValue = Money.zero;
    var totalReturns = Money.zero;
    var pendingReturns = Money.zero;
    List<Map<String, dynamic>> activeInvestments = [];

    for (final investment in investments) {
      final amount = Money.fromKobo(((investment['amount'] as num) * 100).round());
      final returns = Money.fromKobo(((investment['expected_return'] as num) * 100).round());
      
      if (investment['status'] == 'active') {
        totalInvested += amount;
        currentValue += amount + ((returns - amount) * _calculateMaturityProgress(investment));
        pendingReturns += returns - amount;
        activeInvestments.add(investment);
      }
      
      if (investment['status'] == 'completed') {
        totalReturns += returns - amount;
      }
    }

    return {
      'total_invested': {'amountInKobo': totalInvested.amountInKobo},
      'current_value': {'amountInKobo': currentValue.amountInKobo},
      'total_returns': {'amountInKobo': totalReturns.amountInKobo},
      'pending_returns': {'amountInKobo': pendingReturns.amountInKobo},
      'active_investments': activeInvestments,
    };
  }

  double _calculateMaturityProgress(Map<String, dynamic> investment) {
    final startDate = DateTime.parse(investment['start_date']);
    final maturityDate = DateTime.parse(investment['maturity_date']);
    final now = DateTime.now();

    if (now.isAfter(maturityDate)) return 1.0;
    if (now.isBefore(startDate)) return 0.0;

    final totalDuration = maturityDate.difference(startDate).inDays;
    final elapsed = now.difference(startDate).inDays;

    return elapsed / totalDuration;
  }

  Future<List<Map<String, dynamic>>> _fetchGuarantorships() async {
    try {
      final response = await _apiService.getLoans();
      final guarantorships = response
          .where((loan) => loan['guarantor_id'] != null)
          .map((loan) => {
                'id': loan['id'],
                'borrower_name': loan['borrower_name'],
                'amount': loan['amount'],
                'status': loan['status'],
                'guaranteed_date': loan['guaranteed_date'],
                'risk_score': loan['risk_score'] ?? 0.5,
              })
          .toList();
      return guarantorships;
    } catch (e) {
      debugPrint('Error fetching guarantorships: $e');
      return [];
    }
  }

  Future<bool> checkConnectivity() async {
    try {
      // Make a lightweight request to check connectivity
      await _apiService.getWalletBalance();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> applyForLoan({
    required Money amount,
    required String purpose,
    required int termMonths,
  }) async {
    try {
      await _apiService.applyForLoan({
        'amount': amount.amountInKobo,
        'purpose': purpose,
        'term_months': termMonths,
      });
    } catch (e) {
      debugPrint('Error applying for loan: $e');
      rethrow;
    }
  }

  Future<void> rolloverLoan(int additionalMonths) async {
    try {
      await _apiService.rolloverLoan({
        'additional_months': additionalMonths,
      });
    } catch (e) {
      debugPrint('Error rolling over loan: $e');
      rethrow;
    }
  }
}

DashboardData _parseDashboardData(String jsonStr) {
  return DashboardData.fromJson(jsonStr as Map<String, dynamic>);
}
