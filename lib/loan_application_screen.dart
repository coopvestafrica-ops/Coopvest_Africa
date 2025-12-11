import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LoanApplicationScreen extends StatefulWidget {
  final String userId;

  const LoanApplicationScreen({
    super.key,
    required this.userId,
  });

  @override
  State<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends State<LoanApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _savingsWhileOnLoanController =
      TextEditingController();
  bool _showQr = false;
  String _loanId = '';
  String _loanStatus =
      'Pending Review'; // Possible: Pending Review, Approved, Rejected
  String? _rejectionReason;
  String _selectedLoanType = 'Quick Loan';
  final Map<String, Map<String, dynamic>> _loanTypes = {
    'Quick Loan': {'duration': 4, 'interest': 7.5},
    'Flexi Loan': {'duration': 6, 'interest': 7},
    'Stable Loan (12 months)': {'duration': 12, 'interest': 5},
    'Stable Loan (18 months)': {'duration': 18, 'interest': 7},
    'Premium Loan': {'duration': 24, 'interest': 14},
    'Maxi Loan': {'duration': 36, 'interest': 19},
  };

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _loanId = '${widget.userId}-${DateTime.now().millisecondsSinceEpoch}';
        _showQr = true;
        _loanStatus = 'Processing';
        _rejectionReason = null;
      });

      try {
        final requestedAmount =
            double.parse(_amountController.text.replaceAll(',', ''));

        // Simple validation: only check monthly savings commitment
        final monthlySavings =
            double.tryParse(_savingsWhileOnLoanController.text) ?? 0.0;

        setState(() {
          if (monthlySavings >= requestedAmount * 0.1) {
            // Requires 10% monthly savings commitment
            _loanStatus = 'Approved';
            _rejectionReason = null;
          } else {
            _loanStatus = 'Rejected';
            _rejectionReason =
                'Monthly savings commitment must be at least 10% of loan amount';
          }
        });
      } catch (e) {
        setState(() {
          _loanStatus = 'Rejected';
          _rejectionReason = 'Error processing application: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan Application')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLoanType,
                    decoration: const InputDecoration(
                      labelText: 'Loan Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _loanTypes.keys.map((type) {
                      final info = _loanTypes[type]!;
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                            '$type - ${info['duration']} months @ ${info['interest']}%'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedLoanType = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Loan Amount',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter loan amount';
                      }
                      if (double.tryParse(value) == null)
                        return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _savingsWhileOnLoanController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Savings While On Loan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _purposeController,
                    decoration: const InputDecoration(
                      labelText: 'Loan Purpose',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter purpose';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Submit Application'),
                    ),
                  ),
                ],
              ),
            ),
            if (_showQr) ...[
              const SizedBox(height: 32),
              Card(
                color: _loanStatus == 'Approved'
                    ? Colors.green[50]
                    : _loanStatus == 'Rejected'
                        ? Colors.red[50]
                        : Colors.yellow[50],
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _loanStatus == 'Approved'
                                ? Icons.check_circle
                                : _loanStatus == 'Rejected'
                                    ? Icons.cancel
                                    : Icons.hourglass_top,
                            color: _loanStatus == 'Approved'
                                ? Colors.green
                                : _loanStatus == 'Rejected'
                                    ? Colors.red
                                    : Colors.orange,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Status: $_loanStatus',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: _loanStatus == 'Approved'
                                  ? Colors.green
                                  : _loanStatus == 'Rejected'
                                      ? Colors.red
                                      : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      if (_loanStatus == 'Rejected' &&
                          _rejectionReason != null) ...[
                        const SizedBox(height: 8),
                        Text('Reason: $_rejectionReason',
                            style: const TextStyle(color: Colors.red)),
                      ],
                      if (_loanStatus == 'Processing') ...[
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Processing your application...'),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Share this QR code with your 3 guarantors:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Center(
                child: QrImageView(
                  data: _loanId,
                  version: QrVersions.auto,
                  size: 180.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                  'Guarantors should scan this code to stand in. If the borrower defaults, the loan is inherited by the 3 guarantors.'),
            ],
          ],
        ),
      ),
    );
  }
}
