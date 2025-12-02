import 'package:flutter/material.dart';

class WalletScreen extends StatelessWidget {
  final String userId;
  
  const WalletScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final transactions = [
      {'title': 'Deposit', 'amount': '+₦20,000', 'date': '2025-07-01', 'type': 'credit'},
      {'title': 'Withdrawal', 'amount': '-₦5,000', 'date': '2025-07-03', 'type': 'debit'},
      {'title': 'Contribution', 'amount': '-₦2,000', 'date': '2025-07-05', 'type': 'debit'},
      {'title': 'Interest', 'amount': '+₦500', 'date': '2025-07-10', 'type': 'credit'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.all(Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Balance', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 8),
                Text('₦120,000', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isCredit = tx['type'] == 'credit';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCredit ? Colors.green.withValues(alpha: 26) : Colors.red.withValues(alpha: 26),
                    child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? Colors.green : Colors.red),
                  ),
                  title: Text(tx['title']!),
                  subtitle: Text(tx['date']!),
                  trailing: Text(
                    tx['amount']!,
                    style: TextStyle(
                      color: isCredit ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ).copyWith(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
