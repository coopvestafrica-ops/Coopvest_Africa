import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/loan_state.dart';
import '../widgets/loan_form.dart';
import '../widgets/loan_status_card.dart';
import '../widgets/guarantor_qr_code.dart';
import '../widgets/guarantor_approval_dialog.dart';
import '../../domain/models/loan_application_status.dart' as app_status;
import '../../../../core/config/loan_config.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/loading_overlay.dart';

class LoanScreen extends StatefulWidget {
  final String userId;
  
  const LoanScreen({
    super.key,
    required this.userId,
  });

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _savingsWhileOnLoanController = TextEditingController();
  late final LoanState _loanState;

  @override
  void initState() {
    super.initState();
    _loanState = context.read<LoanState>();
    // Load current loan data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loanState.refreshLoanStatus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _savingsWhileOnLoanController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _loanState.submitLoanApplication(
        userId: widget.userId,
        loanAmount: double.parse(_amountController.text),
        purpose: _purposeController.text,
        monthlySavings: double.tryParse(_savingsWhileOnLoanController.text) ?? 0.0,
        tenureMonths: LoanConfig.loanTypes[_loanState.selectedLoanType]?['duration'] as int? ?? 12,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loan application submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting application: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Loan Application Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection(
                'Loan Types',
                '• Quick Loan: For emergency needs\n'
                '• Flexi Loan: Flexible terms and amounts\n'
                '• Stable Loan: Fixed terms, lower rates\n'
                '• Premium Loan: Higher amounts, longer terms',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                'Requirements',
                '• Must be an active member\n'
                '• Have regular savings\n'
                '• Up to date on all payments\n'
                '• Valid guarantors',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                'Guarantors',
                '• Must be active members\n'
                '• Must have sufficient savings\n'
                '• Can guarantee up to 3 loans\n'
                '• Will scan QR code to approve',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(content),
      ],
    );
  }

  Widget _buildNoteSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Important Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Keep up with your regular savings while on loan\n'
              '• Prompt repayment improves your loan limit\n'
              '• Update your guarantors if any changes occur\n'
              '• Contact support if you need assistance',
            ),
          ],
        ),
      ),
    );
  }

  void _showRolloverDialog() {
    final eligibilityData = _loanState.rolloverEligibility!;
    final remainingAmount = eligibilityData.requirements?['remainingAmount'] as double? ?? 0.0;
    final paymentPercentage = eligibilityData.requirements?['paymentPercentage'] as double? ?? 0.0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Loan Rollover Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You have paid ${paymentPercentage.toStringAsFixed(1)}% of your current loan.'),
            const SizedBox(height: 8),
            Text('Remaining balance: ${CurrencyFormatter.format(remainingAmount)}'),
            const SizedBox(height: 16),
            const Text(
              'Benefits of rolling over:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              '• Remaining balance added to new loan\n'
              '• Access to higher loan amount\n'
              '• Extended repayment period\n'
              '• No need for new guarantors'
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Loan Amount',
                border: OutlineInputBorder(),
                helperText: 'Enter the total amount for your new loan'
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _processRollover(),
            child: const Text('Proceed with Rollover'),
          ),
        ],
      ),
    );
  }

  Future<void> _processRollover() async {
    if (_amountController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the new loan amount')),
      );
      return;
    }

    final newAmount = CurrencyFormatter.parse(_amountController.text);
    if (newAmount == null || newAmount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid loan amount')),
      );
      return;
    }

    final selectedLoanType = _loanState.selectedLoanType;
    final loanConfig = LoanConfig.loanTypes[selectedLoanType];
    
    if (loanConfig == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid loan type selected')),
      );
      return;
    }

    // Validate amount against loan type limits
    final minAmount = (loanConfig['minAmount'] as num?)?.toDouble() ?? 0.0;
    final maxAmount = (loanConfig['maxAmount'] as num?)?.toDouble() ?? double.infinity;

    if (newAmount < minAmount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Amount cannot be less than ${CurrencyFormatter.format(minAmount)}')),
      );
      return;
    }

    if (newAmount > maxAmount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Amount cannot exceed ${CurrencyFormatter.format(maxAmount)}')),
      );
      return;
    }

    // Verify rollover eligibility again
    try {
      await _loanState.checkRolloverEligibility(_loanState.loanId!);
      if (_loanState.rolloverEligibility?.isEligible != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are no longer eligible for rollover'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await _loanState.processRollover(
        oldLoanId: _loanState.loanId!,
        userId: widget.userId,
        newAmount: newAmount,
        tenureMonths: loanConfig['duration'] as int,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close amount input dialog

      // Show guarantor approval dialog if needed
      if (_loanState.guarantors.isNotEmpty) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => GuarantorApprovalDialog(
            requestId: result.id,
            guarantors: _loanState.guarantors.map((g) => g.toMap()).toList(),
          ),
        );
      }

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rollover request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing rollover: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Application'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Consumer<LoanState>(
        builder: (context, loanState, _) {
          final bool showQr = loanState.status != app_status.LoanApplicationStatus.initial;
          final bool isLoading = loanState.isLoading;

          if (loanState.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loanState.errorMessage!),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'Dismiss',
                    onPressed: () => loanState.clearError(),
                  ),
                ),
              );
              loanState.clearError();
            });
          }

          return LoadingOverlay(
            isLoading: isLoading,
            message: loanState.status == app_status.LoanApplicationStatus.submitting 
              ? 'Submitting your loan application...'
              : 'Processing your request...',
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LoanForm(
                    formKey: _formKey,
                    amountController: _amountController,
                    purposeController: _purposeController,
                    savingsController: _savingsWhileOnLoanController,
                    selectedLoanType: loanState.selectedLoanType,
                    onLoanTypeChanged: (val) => loanState.setSelectedLoanType(val!),
                    onSubmit: _submit,
                  ),
                  if (showQr) ...[
                    const SizedBox(height: 32),
                    LoanStatusCard(
                      status: loanState.status,
                      rejectionReason: loanState.rejectionReason,
                      onSimulateReview: (approve, reason) => 
                          loanState.simulateStaffReview(approve: approve, reason: reason),
                    ),
                    if (loanState.loanId != null) 
                      GuarantorQRCode(loanId: loanState.loanId!),
                  ],
                  const SizedBox(height: 24),
                  _buildNoteSection(context),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Consumer<LoanState>(
        builder: (context, loanState, _) {
          final isEligible = loanState.rolloverEligibility?.isEligible == true;
          return isEligible
              ? FloatingActionButton.extended(
                  onPressed: _showRolloverDialog,
                  label: const Text('Rollover Loan'),
                  icon: const Icon(Icons.sync),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }
}
