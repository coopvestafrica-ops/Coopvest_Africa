import 'package:flutter/material.dart';

class GuarantorApprovalDialog extends StatelessWidget {
  final String requestId;
  final List<Map<String, dynamic>> guarantors;

  const GuarantorApprovalDialog({
    super.key,
    required this.requestId,
    required this.guarantors,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Waiting for Guarantor Approval'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Request ID: $requestId'),
          const SizedBox(height: 16),
          ...guarantors.map((g) {
            final approved = g['approvedRollover'] as bool? ?? false;
            final name = g['fullName'] as String? ?? 'Unknown';

            return ListTile(
              leading: Icon(
                approved ? Icons.check_circle : Icons.pending,
                color: approved ? Colors.green : Colors.orange,
              ),
              title: Text(name),
              subtitle: Text(approved ? 'Approved' : 'Pending approval'),
            );
          }),
          const SizedBox(height: 16),
          const Text(
            'Your guarantors will be notified to approve the rollover request. '
            'You will be notified once all approvals are received.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
