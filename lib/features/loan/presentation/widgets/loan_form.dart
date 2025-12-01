import 'package:flutter/material.dart';
import '../../../../core/config/loan_config.dart';
import '../../../../core/utils/currency_formatter.dart';

class LoanForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final TextEditingController purposeController;
  final TextEditingController savingsController;
  final String selectedLoanType;
  final ValueChanged<String?> onLoanTypeChanged;
  final VoidCallback onSubmit;
  final bool isLoading;

  const LoanForm({
    super.key,
    required this.formKey,
    required this.amountController,
    required this.purposeController,
    required this.savingsController,
    required this.selectedLoanType,
    required this.onLoanTypeChanged,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final loanConfig = LoanConfig.loanTypes[selectedLoanType];
    final minAmount = (loanConfig?['minAmount'] as num?)?.toDouble() ?? 0.0;
    final maxAmount =
        (loanConfig?['maxAmount'] as num?)?.toDouble() ?? double.infinity;
    final interestRate =
        (loanConfig?['interestRate'] as num?)?.toDouble() ?? 0.0;
    final duration = (loanConfig?['duration'] as int?) ?? 0;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedLoanType,
            decoration: const InputDecoration(
              labelText: 'Loan Type',
              border: OutlineInputBorder(),
            ),
            items: LoanConfig.loanTypes.keys.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: onLoanTypeChanged,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Loan Amount',
              border: const OutlineInputBorder(),
              helperText: 'Min: ${CurrencyFormatter.format(minAmount)}, '
                  'Max: ${maxAmount < double.infinity ? CurrencyFormatter.format(maxAmount) : "No limit"}',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a loan amount';
              }
              final amount = CurrencyFormatter.parse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid amount';
              }
              if (amount < minAmount) {
                return 'Amount cannot be less than ${CurrencyFormatter.format(minAmount)}';
              }
              if (amount > maxAmount) {
                return 'Amount cannot exceed ${CurrencyFormatter.format(maxAmount)}';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: purposeController,
            decoration: const InputDecoration(
              labelText: 'Loan Purpose',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please state your loan purpose';
              }
              if (value.length < 10) {
                return 'Please provide more details about your loan purpose';
              }
              return null;
            },
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: savingsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monthly Savings While on Loan',
              border: OutlineInputBorder(),
              helperText:
                  'How much can you save monthly during loan repayment?',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your planned monthly savings';
              }
              final amount = CurrencyFormatter.parse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loan Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text('Interest Rate: ${interestRate.toStringAsFixed(1)}%'),
                Text('Duration: $duration months'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Submitting...'),
                    ],
                  )
                : const Text('Submit Application'),
          ),
        ],
      ),
    );
  }
}
