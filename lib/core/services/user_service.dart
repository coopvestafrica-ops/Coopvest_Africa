import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  // TODO: Replace with actual API calls
  Future<Map<String, dynamic>> getUserData(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    return <String, dynamic>{
      'savings': 250000.0,
      'activeLoan': 100000.0,
      'nextPaymentDate': DateTime(2025, 8, 30),
      'monthlyContribution': 25000.0,
    };
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored user data
  }
}
