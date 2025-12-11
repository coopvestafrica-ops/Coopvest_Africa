import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/providers/loan_status_provider.dart';
import '../widgets/loan_progress_indicator.dart';
import '../widgets/guarantor_status_card.dart';
import '../widgets/loan_status_badge.dart';
import '../widgets/animated_number.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/exceptions/api_exception.dart';
import 'loan_qr_confirmation_screen.dart';

class LoanStatusScreen extends StatefulWidget {
  final String loanId;
  final double amount;
  final int durationMonths;
  final String purpose;
  final DateTime applicationDate;

  const LoanStatusScreen({
    super.key,
    required this.loanId,
    required this.amount,
    required this.durationMonths,
    required this.purpose,
    required this.applicationDate,
  });

  @override
  State<LoanStatusScreen> createState() => _LoanStatusScreenState();
}

class _LoanStatusScreenState extends State<LoanStatusScreen> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  StreamSubscription<LoanUpdateType>? _updateSubscription;
  late final LoanStatusProvider _loanStatusProvider;

  void _handleLoanUpdate(LoanUpdateType updateType) {
    if (!mounted) return;

    switch (updateType) {
      case LoanUpdateType.status:
        // Show subtle indicator that status was updated
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loan status updated'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case LoanUpdateType.guarantor:
        // Show guarantor update notification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guarantor information updated'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      default:
        break;
    }
  }

  Future<void> _loadData({bool enableAutoRefresh = false}) async {
    try {
      final response = await _loanStatusProvider.loadLoanStatus(
        widget.loanId,
        enableAutoRefresh: enableAutoRefresh,
      );

      if (!response.isSuccess && mounted) {
        throw ApiException(response.error ?? 'Failed to load loan status');
      }
    } catch (e) {
      if (!mounted) return;
      
      final message = e is ApiException ? e.message : 'An unexpected error occurred';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _loadData(enableAutoRefresh: enableAutoRefresh),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loanStatusProvider = Provider.of<LoanStatusProvider>(context, listen: false);
    _updateSubscription = _loanStatusProvider.updates.listen(_handleLoanUpdate);
    _loadData(enableAutoRefresh: true);
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    _loanStatusProvider.disableAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoanStatusProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Loan Status'),
            actions: [
              if (!provider.isLoading) ...[
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _refreshKey.currentState?.show(),
                  tooltip: 'Refresh status',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'auto_refresh':
                        if (provider.isAutoRefreshEnabled) {
                          provider.disableAutoRefresh();
                        } else {
                          provider.enableAutoRefresh();
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    CheckedPopupMenuItem<String>(
                      value: 'auto_refresh',
                      checked: provider.isAutoRefreshEnabled,
                      child: const Text('Auto refresh'),
                    ),
                  ],
                ),
              ],
            ],
          ),
          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(LoanStatusProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading loan status...'),
          ],
        ),
      );
    }

    if (provider.hasError) {
      return ErrorRetryWidget(
        message: provider.error ?? 'Failed to load loan status. Please try again.',
        onRetry: () => _loadData(enableAutoRefresh: false),
      );
    }

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: () => _loadData(enableAutoRefresh: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLoanDetailsCard(provider),
            const SizedBox(height: 24),
            if (provider.loanStatus != null) ...[
              Hero(
                tag: 'loan_progress_${widget.loanId}',
                child: LoanProgressIndicator(
                  totalAmount: provider.loanStatus!.totalAmount,
                  amountPaid: provider.loanStatus!.amountPaid,
                  nextPaymentDate: provider.loanStatus!.nextPaymentDate,
                  lastPaymentDate: provider.loanStatus!.lastPaymentDate,
                ),
              ),
              const SizedBox(height: 24),
            ],
            _buildGuarantorsCard(provider),
            if (provider.canAddMoreGuarantors().isSuccess) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoanQRConfirmationScreen(
                        loanData: {
                          'id': widget.loanId,
                          'amount': widget.amount,
                          'duration': widget.durationMonths,
                          'purpose': widget.purpose,
                        },
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadData();
                  }
                },
                icon: const Icon(Icons.qr_code),
                label: const Text('Show Guarantor QR Code'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoanDetailsCard(LoanStatusProvider provider) {
    final status = provider.loanStatus;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Loan Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (status != null)
                  LoanStatusBadge(status: status.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              'Amount:',
              CurrencyFormatter.format(widget.amount),
              showIcon: true,
              icon: Icons.attach_money,
            ),
            _buildDetailRow(
              context,
              'Purpose:',
              widget.purpose,
              showIcon: true,
              icon: Icons.description,
            ),
            _buildDetailRow(
              context,
              'Duration:',
              '${widget.durationMonths} months',
              showIcon: true,
              icon: Icons.calendar_today,
            ),
            _buildDetailRow(
              context,
              'Application Date:',
              DateFormatter.format(widget.applicationDate.toString()),
              showIcon: true,
              icon: Icons.event,
            ),
            if (status?.rejectionReason != null)
              _buildDetailRow(
                context,
                'Reason:',
                status!.rejectionReason!,
                color: Colors.red,
                showIcon: true,
                icon: Icons.warning,
              ),
            if (provider.loanStatus != null) ...[
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount Due:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  AnimatedNumber(
                    value: provider.loanStatus!.totalAmount.toDouble(),
                    prefix: 'NGN ',
                    style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amount Paid:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  AnimatedNumber(
                    value: provider.loanStatus!.amountPaid.toDouble(),
                    prefix: 'NGN ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuarantorsCard(LoanStatusProvider provider) {
    final guarantors = provider.guarantors;
    final canAddResponse = provider.canAddMoreGuarantors();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Guarantors',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${guarantors.length}/3',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            if (!canAddResponse.isSuccess && canAddResponse.error != null) ...[
              const SizedBox(height: 16),
              Text(
                canAddResponse.error!,
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (guarantors.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    'No guarantors yet\nShare your loan code to add guarantors',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ] else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: guarantors.length,
                itemBuilder: (context, index) {
                  final guarantor = guarantors[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: GuarantorStatusCard(
                      guarantor: guarantor,
                      onRefresh: () async {
                        try {
                          final response = await provider.refreshGuarantor(
                            widget.loanId,
                            guarantor.id,
                          );
                          
                          if (!response.isSuccess && mounted) {
                            throw ApiException(response.error ?? 'Failed to refresh guarantor');
                          }
                        } catch (e) {
                          if (!mounted) return;
                          
                          final message = e is ApiException ? e.message : 'An unexpected error occurred';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              action: SnackBarAction(
                                label: 'Retry',
                                onPressed: () => provider.refreshGuarantor(
                                  widget.loanId,
                                  guarantor.id,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, dynamic value, {
    Color? color,
    bool showIcon = false,
    IconData? icon,
  }) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Row(
              children: [
                if (showIcon && icon != null) ...[
                                    Icon(
                    icon,
                    size: 16,
                    color: textColor.withAlpha(179),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(
                color: color ?? textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
