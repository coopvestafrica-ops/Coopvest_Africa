import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/money.dart';
import '../../../../core/models/transaction_type.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/recent_tickets_card.dart';
import '../../../tickets/presentation/screens/create_ticket_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();

    if (dashboardProvider.isLoading && dashboardProvider.dashboardData == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (dashboardProvider.error != null && dashboardProvider.dashboardData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(dashboardProvider.error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => dashboardProvider.loadDashboardData(forceRefresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: Navigate to profile
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async => await dashboardProvider.refreshDashboard(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserOverviewCard(dashboardProvider),
                    const SizedBox(height: 16),
                    _buildQuickActionsGrid(dashboardProvider),
                    const SizedBox(height: 16),
                    _buildFinancialOverviewChart(dashboardProvider),
                    const SizedBox(height: 16),
                    _buildLoanAndInvestmentStatus(dashboardProvider),
                    const SizedBox(height: 16),
                    _buildRecentTransactions(dashboardProvider),
                    const SizedBox(height: 16),
                    const RecentTicketsCard(),
                  ],
                ),
              ),
            ),
          ),
          if (dashboardProvider.isLoading) _buildLoadingOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: dashboardProvider.canApplyForLoan
            ? () => _showLoanApplicationDialog(context, dashboardProvider)
            : null,
        label: const Text('Apply for Loan'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUserOverviewCard(DashboardProvider provider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildOverviewItem(
                  'Wallet Balance',
                  provider.walletOverview.balance,
                  Icons.account_balance_wallet,
                ),
                _buildOverviewItem(
                  'Total Savings',
                  provider.savingsOverview.totalSavings,
                  Icons.savings,
                ),
                _buildOverviewItem(
                  'Active Loans',
                  provider.loanOverview.activeLoanAmount,
                  Icons.money,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(String title, Money amount, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          amount.toFormattedString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Updating dashboard...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(DashboardProvider provider) {
    final actions = [
      ('Apply for Loan', Icons.add_card, () => _showLoanApplicationDialog(context, provider)),
      ('Create Ticket', Icons.support_agent, () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTicketScreen()),
          )),
      ('Make Investment', Icons.trending_up, () {}),
      ('View Guarantees', Icons.people, () {}),
      ('Savings History', Icons.history, () {}),
      ('Download Statement', Icons.download, () {}),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final (title, icon, onTap) = actions[index];
        return Card(
          elevation: 2,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinancialOverviewChart(DashboardProvider provider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black12),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 3),
                        const FlSpot(2, 2),
                        const FlSpot(4, 5),
                        const FlSpot(6, 3.1),
                        const FlSpot(8, 4),
                        const FlSpot(10, 3),
                      ],
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanAndInvestmentStatus(DashboardProvider provider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loan & Investment Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusItem(
              'Active Loan',
              provider.loanOverview.activeLoanAmount.toFormattedString(),
              'Due: ${provider.loanOverview.nextRepaymentDate?.toString() ?? 'No active loan'}',
              provider.loanOverview.activeLoanAmount.isPositive ? 0.6 : 0,
            ),
            const Divider(),
            _buildStatusItem(
              'Investment Portfolio',
              provider.investmentOverview.currentValue.toFormattedString(),
              'Returns: ${provider.investmentOverview.totalReturns.toFormattedString()}',
              provider.investmentOverview.totalInvested.isPositive ? 0.8 : 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
    String title,
    String amount,
    String subtitle,
    double progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            CircularProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(DashboardProvider provider) {
    final transactions = provider.recentTransactions;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full transaction history
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            if (transactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No recent transactions'),
                ),
              )
            else
              ...transactions.map((t) => ListTile(
                    leading: Icon(_getTransactionIcon(t.type)),
                    title: Text(t.description),
                    subtitle: Text(t.timestamp.toString()),
                    trailing: Text(
                      t.amount.toFormattedString(withSymbol: true),
                      style: TextStyle(
                        color: t.type.isInflow ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> _showLoanApplicationDialog(BuildContext context, DashboardProvider provider) async {
    if (!provider.canApplyForLoan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are not eligible for a new loan at this time'),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    Money? amount;
    String? purpose;
    int? term;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply for Loan'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Loan Amount',
                  prefixText: '₦',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final parsedAmount = double.tryParse(value);
                  if (parsedAmount == null) {
                    return 'Please enter a valid amount';
                  }
                  final money = Money.fromNaira(parsedAmount);
                  if (money > provider.loanOverview.maximumEligibleAmount) {
                    return 'Amount exceeds maximum eligible amount (${provider.loanOverview.maximumEligibleAmount.toFormattedString()})';
                  }
                  return null;
                },
                onSaved: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed != null) {
                    amount = Money.fromNaira(parsed);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Purpose of Loan',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter loan purpose';
                  }
                  return null;
                },
                onSaved: (value) => purpose = value,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Loan Term (months)',
                ),
                items: [3, 6, 12, 24]
                    .map((months) => DropdownMenuItem(
                          value: months,
                          child: Text('$months months'),
                        ))
                    .toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a loan term';
                  }
                  return null;
                },
                onChanged: (value) => term = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                if (amount != null && purpose != null && term != null) {
                  await provider.applyForLoan(
                    amount: amount!,
                    purpose: purpose!,
                    termMonths: term!,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.credit:
        return Icons.arrow_circle_up;
      case TransactionType.debit:
      case TransactionType.withdrawal:
        return Icons.arrow_circle_down;
      case TransactionType.transfer:
        return Icons.swap_horiz;
      case TransactionType.investment:
        return Icons.trending_up;
      case TransactionType.refund:
        return Icons.restore;
      case TransactionType.other:
        return Icons.money;
    }
  }
}