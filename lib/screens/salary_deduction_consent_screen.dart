import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import '../core/theme/app_theme.dart'; // Commented out to fix build

class SalaryDeductionConsentScreen extends StatefulWidget {
  final Map<String, dynamic> registrationData;

  const SalaryDeductionConsentScreen({
    super.key,
    required this.registrationData,
  });

  @override
  State<SalaryDeductionConsentScreen> createState() => _SalaryDeductionConsentScreenState();
}

class _SalaryDeductionConsentScreenState extends State<SalaryDeductionConsentScreen> {
  bool _hasReadConsent = false;
  bool _isLoading = false;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _validateAndInitialize();
  }

  Future<void> _validateAndInitialize() async {
    try {
      setState(() => _isLoading = true);

      // Check authentication
      if (_auth.currentUser == null) {
        _handleError('Authentication required', shouldNavigateToSignup: true);
        return;
      }

      final currentUid = _auth.currentUser!.uid;
      
      // Check if user data exists
      final userDoc = await _firestore.collection('users').doc(currentUid).get();
      
      if (!userDoc.exists) {
        _handleError('User profile not found', shouldNavigateToSignup: true);
        return;
      }

      // Check if consent already given
      if (userDoc.data()?['hasGivenSalaryDeductionConsent'] == true) {
        _handleError(
          'Salary deduction consent already provided',
          shouldNavigateToSignup: false,
          navigateTo: '/dashboard'
        );
        return;
      }

      // Validate registration data
      if (!widget.registrationData.containsKey('uid') || 
          widget.registrationData['uid']?.toString() != currentUid) {
        _handleError(
          'Invalid registration data',
          shouldNavigateToSignup: true
        );
        return;
      }

    } catch (e) {
      _handleError(
        'Error initializing: ${e.toString()}',
        shouldNavigateToSignup: false
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleError(
    String message, {
    bool shouldNavigateToSignup = false,
    String? navigateTo,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: shouldNavigateToSignup ? Colors.red : Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );

    if (shouldNavigateToSignup || navigateTo != null) {
      Future.delayed(
        const Duration(seconds: 1),
        () => Navigator.of(context).pushReplacementNamed(
          navigateTo ?? '/signup',
        ),
      );
    }
  }

  Future<void> _submitConsent() async {

    if (!_hasReadConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please read and accept the consent form'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate required registration data
    final requiredFields = [
      'email',
      'username',
      'password',
      'first_name',
      'last_name',
      'employee_id',
      'employer',
    ];

    for (final field in requiredFields) {
      if (!widget.registrationData.containsKey(field) || 
          widget.registrationData[field]?.toString().trim().isEmpty == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Missing required field: ${field.replaceAll('_', ' ')}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Add consent to registration data
      final userData = {
        ...widget.registrationData,
        'hasGivenSalaryDeductionConsent': true,
        'consentTimestamp': DateTime.now().toIso8601String(),
      };

      // Verify user ID
      final userId = _auth.currentUser?.uid;
      if (userId == null || userId.isEmpty) {
        throw Exception('User ID not found');
      }

      // Save consent data to Firestore
      await _firestore.collection('users').doc(userId).update({
        'hasGivenSalaryDeductionConsent': true,
        'consentTimestamp': FieldValue.serverTimestamp(),
        'employeeId': userData['employee_id'],
        'employer': userData['employer'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Redirecting to dashboard...'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to dashboard
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/dashboard',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _submitConsent,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.registrationData['first_name'] as String? ?? '';
    final lastName = widget.registrationData['last_name'] as String? ?? '';
    final fullName = '$firstName $lastName';
    final employeeId = widget.registrationData['employee_id'] ?? '';
    final organization = widget.registrationData['employer'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Deduction Consent'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Coopvest Africa Consent Form',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Authority for Deduction from Salary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Member Information',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Full Name:', fullName),
                          _buildInfoRow('Employee ID / Staff No.:', employeeId),
                          _buildInfoRow('Organization:', organization),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consent Agreement',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'I, $fullName, hereby authorize my employer to deduct from my monthly salary the agreed contribution amount and remit same directly to Coopvest Africa Cooperative Society.',
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'I understand and agree to the following:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 16),
                          _buildConsentItem(
                            'Mandatory Contributions',
                            'My monthly cooperative contributions shall be deducted automatically from my salary and credited to my Coopvest Africa account.',
                          ),
                          _buildConsentItem(
                            'Loan Repayment',
                            'In the event of a loan facility granted to me by Coopvest Africa, I authorize my employer to deduct loan repayments (including interest where applicable) directly from my salary until the facility is fully liquidated.',
                          ),
                          _buildConsentItem(
                            'Voluntary Consent',
                            'This authorization is given willingly without coercion and remains valid until revoked in writing by me, subject to the cooperative\'s policies.',
                          ),
                          _buildConsentItem(
                            'Binding Commitment',
                            'I acknowledge that this consent form serves as a binding instruction to my employer and Coopvest Africa.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Authorization',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CheckboxListTile(
                            value: _hasReadConsent,
                            onChanged: (value) {
                              setState(() => _hasReadConsent = value ?? false);
                            },
                            title: const Text(
                              'I confirm that I have read, understood, and agreed to the above terms',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            activeColor: Theme.of(context).colorScheme.primary,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          if (_hasReadConsent) ...[
                            _buildInfoRow(
                              'Digital Signature:',
                              fullName,
                            ),
                            _buildInfoRow(
                              'Date:',
                              DateTime.now().toString().split(' ')[0],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitConsent,
                      child: const Text('Submit Consent'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(description),
        ],
      ),
    );
  }
}
