import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GuarantorQRCode extends StatelessWidget {
  final String loanId;

  const GuarantorQRCode({
    super.key, 
    required this.loanId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan to Guarantee',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Have your guarantors scan this QR code to approve the loan',
            ),
            const SizedBox(height: 16),
            Center(
              child: QrImageView(
                data: loanId,
                version: QrVersions.auto,
                size: 200.0,
                embeddedImage: const AssetImage('assets/images/logo.png'),
                embeddedImageStyle: QrEmbeddedImageStyle(
                  size: const Size(40, 40),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Loan ID: $loanId',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
