import 'package:flutter/material.dart';
import 'services/guarantor_service.dart';

class MyGuaranteesScreen extends StatefulWidget {
  const MyGuaranteesScreen({super.key});

  @override
  State<MyGuaranteesScreen> createState() => _MyGuaranteesScreenState();
}

class _MyGuaranteesScreenState extends State<MyGuaranteesScreen> {
  final GuarantorService _guarantorService = GuarantorService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _guarantees = [];

  @override
  void initState() {
    super.initState();
    _loadGuarantees();
  }

  Future<void> _loadGuarantees() async {
    try {
      final response = await _guarantorService.getMyGuarantees();
      setState(() {
        _guarantees = List<Map<String, dynamic>>.from(response['guarantees']);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading guarantees: $e')),
        );
      }
    }
  }

  Future<void> _showRevocationDialog(String loanId) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Revoke Guarantee'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    const TextSpan(
                      text: 'Are you sure you want to revoke your guarantee?\n\n',
                    ),
                    TextSpan(
                      text: 'WARNING:\n',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: '1. Once the loan is approved, you CANNOT revoke your guarantee.\n\n'
                           '2. If you are a guarantor when the loan is approved, you WILL BE LIABLE for 1/3 of the loan amount if the borrower defaults.\n\n'
                           '3. This amount will be AUTOMATICALLY DEDUCTED from your account in case of default.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Revoke'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _guarantorService.revokeGuarantee(loanId, reasonController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guarantee revoked successfully')),
          );
          _loadGuarantees();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to revoke guarantee: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Guarantees'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGuarantees,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _guarantees.length,
                itemBuilder: (context, index) {
                  final guarantee = _guarantees[index];
                  final status = guarantee['status'];
                  final isRevokable = status == 'Pending';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Loan #${guarantee['loan_id']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              _buildStatusChip(status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Amount: ${guarantee['loan_amount']}'),
                          Text('Purpose: ${guarantee['loan_purpose']}'),
                          Text('Applicant: ${guarantee['applicant_name']}'),
                          Text('Date: ${guarantee['guarantee_date']}'),
                          if (isRevokable) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showRevocationDialog(guarantee['loan_id']),
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text('Revoke My Guarantee'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'revoked':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
