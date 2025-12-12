import 'package:flutter/material.dart';
import '../../../../core/models/loan/loan_application_status.dart';

class LoanStatusCard extends StatelessWidget {
  final LoanApplicationStatus status;
  final String? rejectionReason;
  final Function(bool approve, String? reason) onSimulateReview;

  const LoanStatusCard({
    super.key,
    required this.status,
    this.rejectionReason,
    required this.onSimulateReview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Application Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(_getStatusMessage()),
            if (status == LoanApplicationStatus.rejected &&
                rejectionReason != null) ...[
              const SizedBox(height: 8),
              Text(
                'Reason: $rejectionReason',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            // For demo purposes only
            if (status == LoanApplicationStatus.pending) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Demo Controls',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton(
                    onPressed: () => onSimulateReview(true, null),
                    child: const Text('Approve'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () =>
                        onSimulateReview(false, 'Insufficient savings history'),
                    child: const Text('Reject'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusMessage() {
    return status.description;
  }
}
