import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class GuarantorScanScreen extends StatefulWidget {
  const GuarantorScanScreen({super.key});

  @override
  State<GuarantorScanScreen> createState() => _GuarantorScanScreenState();
}

class _GuarantorScanScreenState extends State<GuarantorScanScreen> {
  MobileScannerController? controller;
  String? scannedLoanId;
  bool isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      final ctrl = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      
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

  Future<void> _handleScannedCode(String code) async {
    if (!isScanning || isLoading) return;

    setState(() {
      isLoading = true;
      isScanning = false;
      scannedLoanId = code;
    });

    try {
      // TODO: Implement the API call to register as guarantor
      await Future.delayed(const Duration(seconds: 1)); // Simulated API call

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: Text('You are now registered as a guarantor for loan: $code'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Return to previous screen
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        isScanning = true; // Allow scanning again
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error registering as guarantor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _disposeController() async {
    try {
      final ctrl = controller;
      if (ctrl == null) return;

      setState(() {
        controller = null;
      });

      await ctrl.stop();
      await ctrl.dispose();
    } catch (e) {
      debugPrint('Error disposing camera controller: $e');
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Loan QR Code'),
        actions: [
          if (controller != null)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: () => controller?.switchCamera(),
            ),
          if (controller != null)
            IconButton(
              icon: ValueListenableBuilder(
                valueListenable: ValueNotifier<bool>(false),
                builder: (context, value, child) {
                  return const Icon(Icons.flash_off);
                },
              ),
              onPressed: () => controller?.toggleTorch(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
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
                        if (barcodes.isNotEmpty) {
                          final String code = barcodes.first.rawValue ?? '';
                          if (code.isNotEmpty) {
                            _handleScannedCode(code);
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
          if (scannedLoanId != null && !isLoading) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Processing Loan ID: $scannedLoanId',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
