import 'package:flutter/material.dart';

/// GuarantorStatusBadge - displays the status of a guarantor
class GuarantorStatusBadge extends StatelessWidget {
  final String status;
  final String label;
  final bool isSmall;

  const GuarantorStatusBadge({
    super.key,
    required this.status,
    this.label = '',
    this.isSmall = false,
  });

  /// Get color based on status
  Color _getColor() {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'verified':
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'declined':
      case 'rejected':
      case 'revoked':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  /// Get icon based on status
  IconData _getIcon() {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'verified':
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending_actions;
      case 'declined':
      case 'rejected':
      case 'revoked':
        return Icons.cancel;
      case 'expired':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }

  /// Get label based on status
  String _getLabel() {
    if (label.isNotEmpty) return label;
    
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Accepted';
      case 'pending':
        return 'Pending';
      case 'declined':
        return 'Declined';
      case 'rejected':
        return 'Rejected';
      case 'verified':
        return 'Verified';
      case 'revoked':
        return 'Revoked';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.1),
        border: Border.all(color: _getColor()),
        borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: isSmall ? 12 : 16,
            color: _getColor(),
          ),
          SizedBox(width: isSmall ? 4 : 6),
          Text(
            _getLabel(),
            style: TextStyle(
              fontSize: isSmall ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: _getColor(),
            ),
          ),
        ],
      ),
    );
  }
}
