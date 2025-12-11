import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/utils/qr_data_encoder.dart';

class LoanQRConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> loanData;

  const LoanQRConfirmationScreen({
    super.key,
    required this.loanData,
  });

  @override
  State<LoanQRConfirmationScreen> createState() => _LoanQRConfirmationScreenState();
}

class _LoanQRConfirmationScreenState extends State<LoanQRConfirmationScreen> {
  late final String encodedQRData;
  final GlobalKey qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    encodedQRData = QRDataEncoder.encodeLoanData(widget.loanData);
  }

  Future<void> _shareQRCode() async {
    try {
      await SharePlus.instance.share(
        'Coopvest Africa Loan Guarantor Request\n\n'
        'Amount: ${CurrencyFormatter.format(widget.loanData['amount'])}\n'
        'Duration: ${widget.loanData['duration']} months\n\n'
        'Scan this QR code in the Coopvest Africa app to review and approve:\n\n'
        '$encodedQRData',
        subject: 'Loan Guarantor Request',
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing QR code: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Guarantor QR Code',
        onBack: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Share this QR code with your guarantor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    RepaintBoundary(
                      key: qrKey,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(158, 158, 158, 51), // Colors.grey with 0.2 opacity
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: encodedQRData,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                          errorStateBuilder: (context, error) => Center(
                            child: Text(
                              'Error generating QR code: $error',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Loan Amount: ${CurrencyFormatter.format(widget.loanData['amount'])}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Duration: ${widget.loanData['duration']} months',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      '1. Share this QR code with your potential guarantor\n'
                      '2. They should scan it using the Coopvest Africa app\n'
                      '3. They will review your loan details\n'
                      '4. Once approved, their status will be updated\n'
                      '5. You need 3 guarantors for loan approval',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _shareQRCode,
              icon: const Icon(Icons.share),
              label: const Text('Share QR Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ).copyWith(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'This QR code is valid for 24 hours',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
