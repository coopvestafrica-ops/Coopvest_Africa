import 'package:flutter/material.dart';
import '../models/guarantor.dart';

/// GuarantorCard - displays a guarantor's information in a card format
class GuarantorCard extends StatelessWidget {
  final Guarantor guarantor;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final VoidCallback? onUploadDocuments;
  final bool isRemovable;
  final bool showLiability;

  const GuarantorCard({
    super.key,
    required this.guarantor,
    this.onTap,
    this.onRemove,
    this.onUploadDocuments,
    this.isRemovable = true,
    this.showLiability = true,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'declined':
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  String _getRelationshipLabel(String relationship) {
    switch (relationship.toLowerCase()) {
      case 'friend':
        return '👫 Friend';
      case 'family':
        return '👨‍👩‍👧‍👦 Family';
      case 'colleague':
        return '💼 Colleague';
      case 'business_partner':
        return '🤝 Business Partner';
      default:
        return relationship;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guarantor.guarantorName ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getRelationshipLabel(guarantor.relationship),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(guarantor.confirmationStatus),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(guarantor.confirmationStatus),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Contact info
              if (guarantor.guarantorEmail != null)
                Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        guarantor.guarantorEmail!,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (guarantor.guarantorPhone != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      guarantor.guarantorPhone!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // Verification status
              Row(
                children: [
                  Icon(
                    guarantor.isVerified ? Icons.verified : Icons.pending,
                    size: 16,
                    color: guarantor.isVerified ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Verification: ${guarantor.verificationStatus}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              // Employment verification if required
              if (guarantor.employmentVerificationRequired) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      guarantor.employmentVerificationCompleted
                          ? Icons.check_circle
                          : Icons.pending_actions,
                      size: 16,
                      color: guarantor.employmentVerificationCompleted
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      guarantor.employmentVerificationCompleted
                          ? 'Employment Verified'
                          : 'Employment Verification Required',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
              // Liability amount if shown
              if (showLiability && guarantor.liabilityAmount != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Liability: ₦${guarantor.liabilityAmount?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              // QR code validity
              if (!guarantor.isQrCodeValid) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'QR code has expired',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (onUploadDocuments != null &&
                      guarantor.employmentVerificationRequired &&
                      !guarantor.employmentVerificationCompleted)
                    ElevatedButton.icon(
                      onPressed: onUploadDocuments,
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text('Upload Docs'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  if (isRemovable && onRemove != null)
                    ElevatedButton.icon(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Remove'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
