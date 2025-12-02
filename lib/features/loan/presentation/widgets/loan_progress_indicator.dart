import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

class LoanProgressIndicator extends StatelessWidget {
  final double totalAmount;
  final double amountPaid;
  final String? nextPaymentDate;
  final String? lastPaymentDate;

  const LoanProgressIndicator({
    super.key,
    required this.totalAmount,
    required this.amountPaid,
    this.nextPaymentDate,
    this.lastPaymentDate,
  });

  @override
  Widget build(BuildContext context) {
    final progress = amountPaid / totalAmount;
    final percentage = (progress * 100).toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loan Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paid: ${CurrencyFormatter.format(amountPaid)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Total: ${CurrencyFormatter.format(totalAmount)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 20,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? Colors.green : Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '$percentage% Complete',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (nextPaymentDate != null || lastPaymentDate != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              if (lastPaymentDate != null)
                Text(
                  'Last Payment: ${DateFormatter.format(lastPaymentDate!)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              if (nextPaymentDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Next Payment: ${DateFormatter.format(nextPaymentDate!)}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
