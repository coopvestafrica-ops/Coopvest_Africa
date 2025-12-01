import 'package:flutter/material.dart';

class LoanStatusBadge extends StatelessWidget {
  final String status;
  final bool animated;

  const LoanStatusBadge({
    super.key,
    required this.status,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusData = _getStatusData(status);

    return AnimatedContainer(
      duration: animated ? const Duration(milliseconds: 300) : Duration.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusData.color.withValues(alpha: 26), // alpha 26 ≈ 10% opacity
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: statusData.color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusData.icon != null) ...[
            Icon(
              statusData.icon,
              size: 16,
              color: statusData.color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            statusData.label,
            style: TextStyle(
              color: statusData.color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  _StatusData _getStatusData(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const _StatusData(
          label: 'Approved',
          color: Colors.green,
          icon: Icons.check_circle,
        );
      case 'rejected':
        return const _StatusData(
          label: 'Rejected',
          color: Colors.red,
          icon: Icons.cancel,
        );
      case 'pending':
        return const _StatusData(
          label: 'Pending',
          color: Colors.orange,
          icon: Icons.access_time,
        );
      case 'cancelled':
        return const _StatusData(
          label: 'Cancelled',
          color: Colors.grey,
          icon: Icons.block,
        );
      case 'completed':
        return const _StatusData(
          label: 'Completed',
          color: Colors.blue,
          icon: Icons.task_alt,
        );
      case 'active':
        return const _StatusData(
          label: 'Active',
          color: Colors.green,
          icon: Icons.check_circle,
        );
      case 'defaulted':
        return const _StatusData(
          label: 'Defaulted',
          color: Colors.red,
          icon: Icons.warning,
        );
      case 'rolled_over':
        return const _StatusData(
          label: 'Rolled Over',
          color: Colors.purple,
          icon: Icons.refresh,
        );
      default:
        return _StatusData(
          label: status, // Can't be const because status is dynamic
          color: Colors.grey,
        );
    }
  }
}

class _StatusData {
  final String label;
  final Color color;
  final IconData? icon;

  const _StatusData({
    required this.label,
    required this.color,
    this.icon,
  });
}
