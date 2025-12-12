import 'package:flutter/material.dart';

class SavingsScreen extends StatelessWidget {
  final String userId;
  
  const SavingsScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Savings')),
      body: const Center(child: Text('Savings feature coming soon!')),
    );
  }
}
