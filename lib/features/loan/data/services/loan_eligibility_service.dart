import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import '../models/loan_models.dart';

/// Service for checking loan eligibility based on various criteria including
/// income, employment duration, age, credit score, and debt-to-income ratio.
@immutable
class LoanEligibilityService {
  static const int minimumEmploymentMonths = 12;
  static const double minimumMonthlyIncome = 50000;
  
  // Static loan type definitions
  static const _quickLoan = LoanTypeInfo(interestRate: 0.075, durationMonths: 4);
  static const _flexiLoan = LoanTypeInfo(interestRate: 0.07, durationMonths: 6);
  static const _stableLoan12 = LoanTypeInfo(interestRate: 0.05, durationMonths: 12);
  static const _stableLoan18 = LoanTypeInfo(interestRate: 0.07, durationMonths: 18);
  static const _premiumLoan = LoanTypeInfo(interestRate: 0.14, durationMonths: 24);
  static const _maxiLoan = LoanTypeInfo(interestRate: 0.19, durationMonths: 36);
  static const double maximumLoanToIncomeRatio = 0.33; // 33% of monthly income
  static const int minimumAge = 21;
  static const int maximumAge = 60;
  static const double minimumSavingsRatio = 0.1; // 10% of monthly income
  static const int minimumMembershipMonths = 3;
  static const int maximumActiveLoans = 1;
  static const double minimumCreditScore = 600;
  static const double minimumDebtServiceRatio = 0.5; // 50% of monthly income

  /// Checks if a loan application meets all eligibility criteria
  /// 
  /// Returns a [LoanEligibilityResult] with detailed information about eligibility
  /// and loan terms if eligible.
  /// 
  /// Throws [FormatException] if any input parameters are invalid.
  Future<LoanEligibilityResult> checkEligibility({
    required String dateOfBirth,
    required String employmentDate,
    required String monthlyIncome,
    required String bvn,
    required double requestedAmount,
    required double monthlySavings,
    required String membershipDate,
    required int activeLoans,
    required double creditScore,
    required double existingMonthlyDebt,
  }) async {
    try {
      // Validate all inputs first
      _validateInputs(
        dateOfBirth: dateOfBirth,
        employmentDate: employmentDate,
        monthlyIncome: monthlyIncome,
        bvn: bvn,
        requestedAmount: requestedAmount,
        monthlySavings: monthlySavings,
        membershipDate: membershipDate,
        activeLoans: activeLoans,
        creditScore: creditScore,
        existingMonthlyDebt: existingMonthlyDebt,
      );
      // Parse income from string (remove currency symbol and commas)
      final income = _parseIncome(monthlyIncome);
      
      // Check minimum income
      if (income < minimumMonthlyIncome) {
        return LoanEligibilityResult(
          isEligible: false,
          reason: 'Monthly income must be at least ${_formatCurrency(minimumMonthlyIncome)}',
        );
      }

      // Check employment duration
      final employmentDuration = _calculateEmploymentDuration(employmentDate);
      if (employmentDuration < minimumEmploymentMonths) {
        return const LoanEligibilityResult(
          isEligible: false,
          reason: 'Minimum employment duration required is 12 months',
        );
      }

      // Check age
      final age = _calculateAge(dateOfBirth);
      if (age < minimumAge || age > maximumAge) {
        return LoanEligibilityResult(
          isEligible: false,
          reason: 'Age must be between $minimumAge and $maximumAge years',
        );
      }

      // Check loan amount against income
      final maximumLoanAmount = income * 12 * maximumLoanToIncomeRatio;
      if (requestedAmount > maximumLoanAmount) {
        return LoanEligibilityResult(
          isEligible: false,
          reason: 'Maximum loan amount based on your income is ${_formatCurrency(maximumLoanAmount)}',
        );
      }

      // Check BVN validity
      if (!_isValidBVN(bvn)) {
        return LoanEligibilityResult(
          isEligible: false,
          reason: 'Invalid BVN provided',
        );
      }

      // Check minimum savings
      final minimumSavings = income * minimumSavingsRatio;
      if (monthlySavings < minimumSavings) {
        return LoanEligibilityResult(
          isEligible: false,
          reason: 'Monthly savings must be at least ${_formatCurrency(minimumSavings)} (${minimumSavingsRatio * 100}% of income)',
        );
      }

      // Check membership duration
      final membershipDuration = _calculateDurationInMonths(membershipDate);
      if (membershipDuration < minimumMembershipMonths) {
        return LoanEligibilityResult(
          isEligible: false,
          reason: 'Minimum membership duration required is $minimumMembershipMonths months',
        );
      }

      // Check active loans
      if (activeLoans >= maximumActiveLoans) {
        return const LoanEligibilityResult(
          isEligible: false,
          reason: 'Maximum number of active loans (1) reached',
        );
      }

      // Check credit score
      if (creditScore < minimumCreditScore) {
        return const LoanEligibilityResult(
          isEligible: false,
          reason: 'Minimum credit score required is 600',
        );
      }

      // Calculate monthly loan payment (simple interest calculation)
      final loanTypeInfo = _getLoanTypeInfo(requestedAmount);
      final monthlyPayment = _calculateMonthlyPayment(
        requestedAmount,
        loanTypeInfo.interestRate,
        loanTypeInfo.durationMonths,
      );

      // Check debt service ratio
      final totalMonthlyDebt = existingMonthlyDebt + monthlyPayment;
      final debtServiceRatio = totalMonthlyDebt / income;
      if (debtServiceRatio > minimumDebtServiceRatio) {
        return LoanEligibilityResult(
          isEligible: false,
          reason: 'Total monthly debt payments cannot exceed ${minimumDebtServiceRatio * 100}% of monthly income',
          maximumAmount: _calculateMaxLoanAmount(income - existingMonthlyDebt, loanTypeInfo),
        );
      }

      // All checks passed
      return LoanEligibilityResult(
        isEligible: true,
        reason: 'All eligibility criteria met',
        maximumAmount: maximumLoanAmount,
        loanDetails: LoanDetails(
          monthlyPayment: monthlyPayment,
          interestRate: loanTypeInfo.interestRate,
          durationMonths: loanTypeInfo.durationMonths,
          totalInterest: (monthlyPayment * loanTypeInfo.durationMonths) - requestedAmount,
        ),
      );
    } catch (e) {
      return LoanEligibilityResult(
        isEligible: false,
        reason: 'Error checking eligibility: $e',
      );
    }
  }

  double _parseIncome(String incomeRange) {
    // Remove currency symbol, commas and spaces
    final cleanIncome = incomeRange.replaceAll('₦', '').replaceAll(',', '').replaceAll(' ', '');
    
    // If income range contains hyphen, take the lower value
    if (cleanIncome.contains('-')) {
      return double.parse(cleanIncome.split('-')[0]);
    }
    
    // For "Above X" format, take X as the income
    if (cleanIncome.toLowerCase().contains('above')) {
      return double.parse(cleanIncome.toLowerCase().replaceAll('above', ''));
    }
    
    return double.parse(cleanIncome);
  }

  int _calculateEmploymentDuration(String employmentDate) {
    final employed = DateFormat('yyyy-MM-dd').parse(employmentDate);
    final now = DateTime.now();
    return ((now.difference(employed).inDays) / 30).floor();
  }

  int _calculateAge(String dateOfBirth) {
    final dob = DateFormat('yyyy-MM-dd').parse(dateOfBirth);
    final now = DateTime.now();
    return now.year - dob.year - (now.month < dob.month || (now.month == dob.month && now.day < dob.day) ? 1 : 0);
  }

  bool _isValidBVN(String bvn) {
    // Basic BVN validation (11 digits)
    return bvn.length == 11 && RegExp(r'^\d{11}$').hasMatch(bvn);
  }

  int _calculateDurationInMonths(String date) {
    final fromDate = DateFormat('yyyy-MM-dd').parse(date);
    final now = DateTime.now();
    return ((now.difference(fromDate).inDays) / 30).floor();
  }

  LoanTypeInfo _getLoanTypeInfo(double amount) {
    if (amount <= 100000) {
      return _quickLoan; // Quick loan
    } else if (amount <= 500000) {
      return _flexiLoan; // Flexi loan
    } else if (amount <= 1000000) {
      if (amount <= 750000) {
        return _stableLoan12; // Stable loan 12 months
      } else {
        return _stableLoan18; // Stable loan 18 months
      }
    } else if (amount <= 2000000) {
      return _premiumLoan; // Premium loan
    } else {
      return _maxiLoan; // Maxi loan
    }
  }

  double _calculateMonthlyPayment(double principal, double annualInterestRate, int durationMonths) {
    final monthlyRate = annualInterestRate / 12;
    final totalPayments = durationMonths;
    
    if (monthlyRate == 0) {
      return principal / totalPayments;
    }

    final x = pow(1 + monthlyRate, totalPayments);
    return principal * monthlyRate * x / (x - 1);
  }

  double _calculateMaxLoanAmount(double availableMonthlyPayment, LoanTypeInfo loanType) {
    final monthlyRate = loanType.interestRate / 12;
    final totalPayments = loanType.durationMonths;
    
    if (monthlyRate == 0) {
      return availableMonthlyPayment * totalPayments;
    }

    final x = pow(1 + monthlyRate, totalPayments);
    return availableMonthlyPayment * (x - 1) / (monthlyRate * x);
  }

  double pow(double x, int n) {
    return math.pow(x, n).toDouble();
  }

  /// Validates input parameters before processing
  bool _validateInputs({
    required String dateOfBirth,
    required String employmentDate,
    required String monthlyIncome,
    required String bvn,
    required double requestedAmount,
    required double monthlySavings,
    required String membershipDate,
    required int activeLoans,
    required double creditScore,
    required double existingMonthlyDebt,
  }) {
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    
    if (!dateRegex.hasMatch(dateOfBirth) ||
        !dateRegex.hasMatch(employmentDate) ||
        !dateRegex.hasMatch(membershipDate)) {
      throw const FormatException('Dates must be in YYYY-MM-DD format');
    }

    if (requestedAmount <= 0) {
      throw const FormatException('Requested amount must be greater than 0');
    }

    if (monthlySavings < 0) {
      throw const FormatException('Monthly savings cannot be negative');
    }

    if (activeLoans < 0) {
      throw const FormatException('Active loans count cannot be negative');
    }

    if (creditScore < 0 || creditScore > 1000) {
      throw const FormatException('Credit score must be between 0 and 1000');
    }

    if (existingMonthlyDebt < 0) {
      throw const FormatException('Existing monthly debt cannot be negative');
    }

    return true;
  }

  /// Formats currency amount with Naira symbol
  String _formatCurrency(double amount) {
    return '₦${NumberFormat('#,##0.00').format(amount)}';
  }
}
