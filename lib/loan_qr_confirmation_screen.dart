import 'package:flutter/material.dart';
import 'services/loan_qr_generator.dart';

class LoanQRConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> loanData;

  const LoanQRConfirmationScreen({
    super.key,
    required this.loanData,
  });

  @override
  Widget build(BuildContext context) {
    final guarantorCode = LoanQRGenerator.generateGuarantorCode(loanData['loan_id']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Guarantee QR Code'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Share this QR code with your guarantors',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    LoanQRGenerator.generateQRCode(loanData),
                    const SizedBox(height: 16),
                    Text(
                      'Guarantee Code: $guarantorCode',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Loan Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDetailRow('Amount:', loanData['amount'].toString()),
                      _buildDetailRow('Purpose:', loanData['purpose']),
                      _buildDetailRow('Duration:', loanData['duration']),
                      const Divider(),
                      const Text(
                        'Note: You need 3 guarantors to process your loan',
                        style: TextStyle(
                          color: Colors.blue,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }
}
