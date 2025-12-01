import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'services/guarantor_service.dart';
import 'services/guarantor_eligibility_service.dart';

class GuarantorLoanScreen extends StatefulWidget {
  const GuarantorLoanScreen({super.key});

  @override
  State<GuarantorLoanScreen> createState() => _GuarantorLoanScreenState();
}

class _GuarantorLoanScreenState extends State<GuarantorLoanScreen> {
  MobileScannerController? controller;
  String? scanResult;
  final TextEditingController _codeController = TextEditingController();
  bool isLoading = false;
  bool hasAgreed = false;
  Map<String, dynamic>? loanDetails;
  Map<String, dynamic>? eligibilityStatus;
  Map<String, dynamic>? guaranteeStats;
  bool isMembershipValid = false;
  bool meetsSavingsThreshold = false;
  String? savingsMessage;
  bool isScanning = true;

  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      final ctrl = MobileScannerController(
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      
      // Wait for controller to initialize
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      setState(() {
        controller = ctrl;
        _hasError = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        controller = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initializing camera: $_errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _disposeController() async {
    try {
      final ctrl = controller;
      if (ctrl == null) return;

      // Set controller to null first to prevent widget rebuilds from using it
      setState(() {
        controller = null;
      });

      // Stop scanning first
      await ctrl.stop();
      
      // Then dispose
      await ctrl.dispose();
    } catch (e) {
      debugPrint('Error disposing camera controller: $e');
    }
  }

  @override
  void dispose() {
    _disposeController(); // Don't need to await since we're disposing
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _checkEligibility() async {
    try {
      final eligibilityService = GuarantorEligibilityService(baseUrl: 'https://your-api-base-url.com');

      // Check membership status
      isMembershipValid = await eligibilityService.validateMembershipStatus();
      if (!isMembershipValid) {
        throw Exception('Your Coopvest membership must be active to guarantee loans');
      }

      // Check savings threshold
      final savingsCheck = await eligibilityService.checkSavingsThreshold();
      meetsSavingsThreshold = savingsCheck['meets_threshold'];
      savingsMessage = savingsCheck['message'];
      if (!meetsSavingsThreshold) {
        throw Exception(savingsMessage ?? 'Minimum savings threshold not met');
      }

      // Check guarantee limits
      final stats = await eligibilityService.getGuaranteeStats();
      guaranteeStats = stats;
      
      if (stats['active_guarantees'] >= 3) {
        throw Exception(
          'Guarantor Limit Reached – You\'re already backing ${stats['active_guarantees']} active loans. '
          'Wait until one is fully repaid.'
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _fetchLoanDetails(String code) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Check eligibility first
      await _checkEligibility();

      final guarantorService = GuarantorService();
      final details = await guarantorService.getLoanDetails(code);
      final eligibility = await guarantorService.validateGuarantorEligibility(details['loan_id']);
      
      setState(() {
        loanDetails = {
          'applicantName': details['applicant_name'],
          'coopvestId': details['coopvest_id'],
          'loanAmount': details['loan_amount'],
          'loanPurpose': details['loan_purpose'],
          'loan_id': details['loan_id'],
          'currentGuarantors': details['current_guarantors'] ?? 0,
        };
        eligibilityStatus = eligibility;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmGuarantee() async {
    setState(() {
      isLoading = true;
    });

    try {
      final guarantorService = GuarantorService();
      await guarantorService.confirmGuarantee(scanResult ?? _codeController.text);
      
      // Show success dialog
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  const TextSpan(
                    text: 'You have successfully agreed to guarantee this loan.\n\n',
                  ),
                  TextSpan(
                    text: 'IMPORTANT: If the borrower defaults, you will be legally required to pay 1/3 of the remaining loan amount. '
                          'This amount will be automatically deducted from your account.\n\n',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(
                    text: 'This guarantee becomes binding once the loan is approved and cannot be revoked.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Return to dashboard
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming guarantee: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guarantee a Loan'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_hasError)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Camera Error\n${_errorMessage ?? "Unknown error"}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _initializeController,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      else if (controller != null)
                        MobileScanner(
                          controller: controller!,
                          onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty && isScanning) {
                            final String code = barcodes.first.rawValue ?? '';
                            if (code.isNotEmpty) {
                              setState(() {
                                isScanning = false;
                                scanResult = code;
                              });
                              _fetchLoanDetails(code);
                            }
                          }
                        },
                      ),
                      if (isLoading)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Or enter guarantee code manually:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Guarantee Code',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      if (_codeController.text.isNotEmpty) {
                        _fetchLoanDetails(_codeController.text);
                      }
                    },
                  ),
                ),
              ),
              if (isLoading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
              if (loanDetails != null) ...[
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loan Details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Applicant Name:', loanDetails!['applicantName']),
                        _buildDetailRow('Coopvest ID:', loanDetails!['coopvestId']),
                        _buildDetailRow('Loan Amount:', loanDetails!['loanAmount']),
                        _buildDetailRow('Loan Purpose:', loanDetails!['loanPurpose']),
                        const SizedBox(height: 16),
                        if (eligibilityStatus != null && !eligibilityStatus!['isEligible']) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    eligibilityStatus!['message'] ?? 'You are not eligible to guarantee this loan',
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Checkbox(
                                value: hasAgreed,
                                onChanged: (bool? value) {
                                  setState(() {
                                    hasAgreed = value ?? false;
                                  });
                                },
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'IMPORTANT: By agreeing to guarantee this loan:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '1. If the borrower defaults on repayment, you WILL BE LIABLE to repay the remaining loan amount.\n\n'
                                      '2. The loan amount will be AUTOMATICALLY DEDUCTED from your account if the borrower defaults.\n\n'
                                      '3. This guarantee CANNOT BE REVOKED once the loan is approved.',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (loanDetails != null) ...[
                          Text(
                            'Current Guarantors: ${loanDetails!['currentGuarantors']}/3',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: hasAgreed && (eligibilityStatus != null && eligibilityStatus!['isEligible'] == true) ? _confirmGuarantee : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Confirm Guarantee'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
