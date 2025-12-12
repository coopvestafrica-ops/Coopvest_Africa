import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/loan_guarantor.dart';

class GuarantorStatusCard extends StatelessWidget {
  final LoanGuarantor guarantor;
  final VoidCallback onRefresh;

  const GuarantorStatusCard({
    super.key,
    required this.guarantor,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    IconData statusIcon;
    Color statusColor;
    String statusText;
    
    switch (guarantor.status.toLowerCase()) {
      case 'approved':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        statusText = 'Approved';
        break;
      case 'revoked':
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        statusText = 'Revoked';
        break;
      default:
        statusIcon = Icons.pending;
        statusColor = Colors.orange;
        statusText = 'Pending';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                guarantor.fullName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              guarantor.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Member ID: ${guarantor.membershipId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Status: $statusText',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: guarantor.status.toLowerCase() == 'approved'
                ? Container(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              color: statusColor,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                CurrencyFormatter.format(guarantor.guaranteedAmount),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : guarantor.status.toLowerCase() == 'pending'
                    ? IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: onRefresh,
                        tooltip: 'Refresh status',
                      )
                    : Icon(
                        statusIcon,
                        color: statusColor,
                      ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Guaranteed at: ${guarantor.guaranteedAt.toString()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
