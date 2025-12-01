import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GuarantorEligibilityResult {
  final bool isEligible;
  final List<String> reasons;
  final Map<String, bool> criteriaResults;
  final Map<String, dynamic>? user;

  GuarantorEligibilityResult({
    required this.isEligible,
    required this.reasons,
    required this.criteriaResults,
    this.user,
  });

  factory GuarantorEligibilityResult.fromJson(Map<String, dynamic> json) {
    return GuarantorEligibilityResult(
      isEligible: json['isEligible'] as bool,
      reasons: List<String>.from(json['reasons']),
      criteriaResults: Map<String, bool>.from(json['criteria']),
      user: json['user'] as Map<String, dynamic>?,
    );
  }
}

class GuarantorEligibilityService {
  static const double minimumSavings = 20000.0;
  static const int minimumMembershipDays = 60;
  static const int minimumContributions = 3;
  static const int maximumActiveGuarantees = 3;

  final String baseUrl;

  GuarantorEligibilityService({required this.baseUrl});

  Future<GuarantorEligibilityResult> checkEligibility(String memberId) async {
    try {
      final url = Uri.parse('$baseUrl/wp-json/coopvest/v1/members/$memberId/guarantor-eligibility');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GuarantorEligibilityResult.fromJson(data);
      } else {
        if (kDebugMode) {
          print('Error checking guarantor eligibility: ${response.body}');
        }
        throw Exception('Failed to check eligibility: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking guarantor eligibility: $e');
      }
      rethrow;
    }
  }

  Future<double> calculateGuarantorRiskScore(String memberId) async {
    try {
      final url = Uri.parse('$baseUrl/wp-json/coopvest/v1/members/$memberId/risk-score');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Calculate weighted score based on multiple factors
        final savingsScore = data['savingsScore'] ?? 0.0;
        final repaymentScore = data['repaymentScore'] ?? 0.0;
        final contributionScore = data['contributionScore'] ?? 0.0;
        final guaranteeHistoryScore = data['guaranteeHistoryScore'] ?? 0.0;
        
        // Weighted average calculation
        return (savingsScore * 0.3 + 
                repaymentScore * 0.3 + 
                contributionScore * 0.2 + 
                guaranteeHistoryScore * 0.2)
                .clamp(0.0, 100.0);
      } else {
        if (kDebugMode) {
          print('Error calculating risk score: ${response.body}');
        }
        throw Exception('Failed to calculate risk score: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating risk score: $e');
      }
      rethrow;
    }
  }

  Future<bool> validateMembershipStatus() async {
    try {
      final url = Uri.parse('$baseUrl/wp-json/coopvest/v1/members/validate-membership');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isValid'] ?? false;
      } else {
        if (kDebugMode) {
          print('Error validating membership: ${response.body}');
        }
        throw Exception('Failed to validate membership status');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error validating membership: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkSavingsThreshold() async {
    try {
      final url = Uri.parse('$baseUrl/wp-json/coopvest/v1/members/check-savings');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'meets_threshold': data['meetsThreshold'] ?? false,
          'message': data['message'] ?? 'Insufficient savings balance',
          'current_savings': data['currentSavings'],
          'required_savings': data['requiredSavings'],
        };
      } else {
        if (kDebugMode) {
          print('Error checking savings threshold: ${response.body}');
        }
        throw Exception('Failed to check savings threshold');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking savings threshold: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getGuaranteeStats() async {
    try {
      final url = Uri.parse('$baseUrl/wp-json/coopvest/v1/members/guarantee-stats');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'active_guarantees': data['activeGuarantees'] ?? 0,
          'completed_guarantees': data['completedGuarantees'] ?? 0,
          'total_amount_guaranteed': data['totalAmountGuaranteed'] ?? 0,
          'available_guarantee_limit': data['availableGuaranteeLimit'] ?? 0,
        };
      } else {
        if (kDebugMode) {
          print('Error fetching guarantee stats: ${response.body}');
        }
        throw Exception('Failed to fetch guarantee statistics');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching guarantee stats: $e');
      }
      rethrow;
    }
  }
}
