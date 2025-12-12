import 'package:flutter/material.dart';

class ReferralScreen extends StatelessWidget {
  final String referralCode;

  const ReferralScreen({super.key, required this.referralCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Your Referral Code:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SelectableText(
              referralCode,
              style: const TextStyle(fontSize: 24, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Share Referral Code'),
              onPressed: () {
                // Implement sharing logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Referral code copied to clipboard!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}