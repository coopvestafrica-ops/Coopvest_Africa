import 'package:flutter/material.dart';
import '../services/guarantor_eligibility_service.dart';

class GuarantorEligibilityCard extends StatefulWidget {
  final GuarantorEligibilityService service;
  final String memberId;

  const GuarantorEligibilityCard({
    super.key,
    required this.service,
    required this.memberId,
  });

  @override
  State<GuarantorEligibilityCard> createState() => _GuarantorEligibilityCardState();
}

class _GuarantorEligibilityCardState extends State<GuarantorEligibilityCard> {
  late Future<GuarantorEligibilityResult> _eligibilityFuture;

  @override
  void initState() {
    super.initState();
    _eligibilityFuture = widget.service.checkEligibility(widget.memberId);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<GuarantorEligibilityResult>(
          future: _eligibilityFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Error checking eligibility: ${snapshot.error}');
            }

            if (!snapshot.hasData) {
              return const Text('No eligibility data available');
            }

            final result = snapshot.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      result.isEligible ? Icons.check_circle : Icons.error,
                      color: result.isEligible ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Guarantor Eligibility Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!result.isEligible) ...[
                  const Text(
                    'You are not eligible to be a guarantor for the following reasons:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...result.reasons.map((reason) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(reason)),
                      ],
                    ),
                  )),
                ] else
                  const Text(
                    'You are eligible to be a guarantor!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Eligibility Criteria:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildCriteriaItem(
                  'Minimum Savings (₦20,000)',
                  result.criteriaResults['savings'] ?? false,
                ),
                _buildCriteriaItem(
                  'Membership Duration (60 days)',
                  result.criteriaResults['membershipDuration'] ?? false,
                ),
                _buildCriteriaItem(
                  'Contribution History (3 minimum)',
                  result.criteriaResults['contributions'] ?? false,
                ),
                _buildCriteriaItem(
                  'Active Guarantees (Max 3)',
                  result.criteriaResults['activeGuarantees'] ?? false,
                ),
                _buildCriteriaItem(
                  'No Active Defaults',
                  result.criteriaResults['noDefaults'] ?? false,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCriteriaItem(String label, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            color: isMet ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
