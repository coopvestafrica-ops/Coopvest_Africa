import 'package:flutter/material.dart';

class ContributionScreen extends StatelessWidget {
  final String userId;
  
  const ContributionScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contributions')),
      body: const Center(child: Text('Contributions feature coming soon!')),
    );
  }
}
