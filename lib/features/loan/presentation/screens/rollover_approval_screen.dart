import 'package:flutter/material.dart';
import '../../data/services/loan_rollover_service.dart';
import '../../domain/models/rollover_request.dart';
import 'package:provider/provider.dart';

class RolloverApprovalScreen extends StatefulWidget {
  final String requestId;
  final String guarantorId;

  const RolloverApprovalScreen({
    super.key,
    required this.requestId,
    required this.guarantorId,
  });

  @override
  State<RolloverApprovalScreen> createState() => _RolloverApprovalScreenState();
}

class _RolloverApprovalScreenState extends State<RolloverApprovalScreen> {
  late final LoanRolloverService _rolloverService;
  bool _isLoading = false;
  RolloverRequest? _requestDetails;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rolloverService = Provider.of<LoanRolloverService>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    _loadRequestDetails();
  }

  Future<void> _loadRequestDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get all pending requests for this guarantor
      final requests =
          await _rolloverService.getPendingRolloverRequests(widget.guarantorId);

      // Find the specific request we're looking for
      final request = requests.firstWhere(
        (r) => r.id == widget.requestId,
        orElse: () => throw Exception('Request not found or no longer pending'),
      );

      // Verify the request is still pending
      if (request.status != 'pending') {
        throw Exception('This request is no longer pending approval');
      }

      // Verify the guarantor hasn't already approved
      final hasApproved = request.metadata?['hasApproved'] as bool? ?? false;
      if (hasApproved) {
        throw Exception('You have already approved this request');
      }

      if (!mounted) return;
      setState(() {
        _requestDetails = request;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              Navigator.of(context).pop();
            },
          ),
        ),
      );
      setState(() {
        _isLoading = false;
      });

      // Navigate back after showing error
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  Future<void> _approveRollover() async {
    if (!mounted) return;

    // Verify we have request details
    if (_requestDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Request details not loaded'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if already approved
    if (_requestDetails!.metadata?['hasApproved'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already approved this request'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Approval'),
        content: const Text(
          'Are you sure you want to approve this loan rollover?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (shouldProceed != true || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _rolloverService.approveRollover(
        requestId: widget.requestId,
        guarantorId: widget.guarantorId,
      );

      if (!mounted) return;

      // Check if this was the final approval needed
      if (result.status == 'completed') {
        Navigator.of(context).pop(); // Close this screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rollover approved and processed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        final approvalCount = result.metadata?['approvalCount'] as int? ?? 0;
        final totalRequired = result.metadata?['totalRequired'] as int? ?? 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Approval registered ($approvalCount/$totalRequired approvals)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh the request details
        await _loadRequestDetails();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _approveRollover(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final request = _requestDetails!;
    final metadata = request.metadata;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
                'Borrower:', metadata?['borrowerName'] as String? ?? 'Unknown'),
            _buildDetailRow('Current Balance:',
                '₦${metadata?['remainingAmount']?.toStringAsFixed(2) ?? '0.00'}'),
            const Divider(),
            _buildDetailRow('New Loan Amount:',
                '₦${request.newLoanAmount.toStringAsFixed(2)}'),
            _buildDetailRow('New Tenure:', '${request.newTenureMonths} months'),
            const Divider(),
            _buildDetailRow(
              'Approval Status:',
              '${metadata?['approvalCount'] ?? 0}/${metadata?['totalGuarantors'] ?? 0} Guarantors',
            ),
            if (metadata?['hasApproved'] == true)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'You have already approved this request',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Rollover Approval'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Important Notice',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'By approving this loan rollover:\n\n'
                            '• Your guarantee will extend to the new loan amount\n'
                            '• The loan tenure will be extended\n'
                            '• You remain liable if the borrower defaults\n'
                            '• This action cannot be undone',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_requestDetails != null) ...[
                    Text(
                      'Rollover Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailsCard(),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _requestDetails?.metadata?['hasApproved'] == true
                              ? null // Disable if already approved
                              : _approveRollover,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text(
                        'Approve Rollover',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
