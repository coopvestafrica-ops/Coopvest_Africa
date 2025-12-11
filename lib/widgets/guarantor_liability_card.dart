import 'package:flutter/material.dart';

/// GuarantorLiabilityCard - displays guarantor's liability information
class GuarantorLiabilityCard extends StatelessWidget {
  final String guarantorName;
  final double liabilityAmount;
  final double? totalLoanAmount;
  final String relationship;
  final bool isCritical; // If liability is high

  const GuarantorLiabilityCard({
    super.key,
    required this.guarantorName,
    required this.liabilityAmount,
    this.totalLoanAmount,
    required this.relationship,
    this.isCritical = false,
  });

  double? get liabilityPercentage {
    if (totalLoanAmount == null || totalLoanAmount == 0) return null;
    return (liabilityAmount / totalLoanAmount!) * 100;
  }

  Color _getColor() {
    if (isCritical) return Colors.red;
    if (liabilityPercentage != null && liabilityPercentage! > 50) return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _getColor().withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: _getColor().withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guarantorName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      relationship,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (isCritical)
                  Tooltip(
                    message: 'High liability amount',
                    child: Icon(
                      Icons.warning,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Liability amount display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _getColor().withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Liability Amount:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '₦${liabilityAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getColor(),
                    ),
                  ),
                ],
              ),
            ),
            // Percentage of total loan
            if (liabilityPercentage != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Percentage of Loan:',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '${liabilityPercentage!.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getColor(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: liabilityPercentage! / 100,
                  minHeight: 8,
                  backgroundColor: _getColor().withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
                ),
              ),
            ],
            // Warning message if critical
            if (isCritical) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'If borrower defaults, this amount will be deducted from their account',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
