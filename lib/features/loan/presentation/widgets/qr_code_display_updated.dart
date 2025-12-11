import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/services/qr_service.dart';
import '../../../../core/exceptions/api_exception.dart';

/// Updated QRCodeDisplay - Uses backend API for QR generation
class QRCodeDisplayUpdated extends StatefulWidget {
  final String loanId;
  final VoidCallback? onRefresh;
  final VoidCallback? onError;
  final double size;
  final String? label;

  const QRCodeDisplayUpdated({
    super.key,
    required this.loanId,
    this.onRefresh,
    this.onError,
    this.size = 250,
    this.label,
  });

  @override
  State<QRCodeDisplayUpdated> createState() => _QRCodeDisplayUpdatedState();
}

class _QRCodeDisplayUpdatedState extends State<QRCodeDisplayUpdated> {
  late QRService _qrService;
  QRTokenResponse? _qrToken;
  bool _isLoading = true;
  String? _error;
  late DateTime _expiresAt;
  late Timer _expirationTimer;

  @override
  void initState() {
    super.initState();
    _qrService = QRService.instance;
    _generateQRToken();
  }

  @override
  void dispose() {
    _expirationTimer.cancel();
    super.dispose();
  }

  /// Generate QR token from backend
  Future<void> _generateQRToken() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _qrService.generateQRToken(
        loanId: widget.loanId,
        durationMinutes: 15,
      );

      setState(() {
        _qrToken = response;
        _expiresAt = response.expiresAt;
        _isLoading = false;
      });

      // Start expiration timer
      _startExpirationTimer();
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
      widget.onError?.call();
    } catch (e) {
      setState(() {
        _error = 'Failed to generate QR code';
        _isLoading = false;
      });
      widget.onError?.call();
    }
  }

  /// Start timer to update expiration countdown
  void _startExpirationTimer() {
    _expirationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
        
        // Check if expired
        if (DateTime.now().isAfter(_expiresAt)) {
          timer.cancel();
          setState(() {
            _error = 'QR code has expired';
          });
        }
      }
    });
  }

  /// Get formatted time remaining
  String _getTimeRemaining() {
    final remaining = _expiresAt.difference(DateTime.now());
    
    if (remaining.isNegative) {
      return 'Expired';
    }
    
    if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m ${remaining.inSeconds.remainder(60)}s';
    } else {
      return '${remaining.inSeconds}s';
    }
  }

  /// Check if QR is expired
  bool get _isExpired => DateTime.now().isAfter(_expiresAt);

  /// Handle refresh
  Future<void> _handleRefresh() async {
    _expirationTimer.cancel();
    await _generateQRToken();
    widget.onRefresh?.call();
  }

  /// Handle revoke
  Future<void> _handleRevoke() async {
    if (_qrToken == null) return;

    try {
      final success = await _qrService.revokeQRToken(_qrToken!.token);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code revoked successfully')),
        );
        _expirationTimer.cancel();
        await _generateQRToken();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Label
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],

            // Loading state
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),

            // Error state
            if (_error != null && !_isLoading)
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _handleRefresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // QR Code display
            if (_qrToken != null && !_isLoading)
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isExpired ? Colors.red : Colors.green,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isExpired
                      ? _buildExpiredState()
                      : _buildActiveState(),
                ),
              ),

            // Token info
            if (_qrToken != null && !_isLoading) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Token:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _qrToken!.token,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            if (_qrToken != null && !_isLoading) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _handleRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _handleRevoke,
                    icon: const Icon(Icons.close),
                    label: const Text('Revoke'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
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

  /// Build active QR state
  Widget _buildActiveState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QR Code
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: QrImageView(
            data: _qrToken!.token,
            version: QrVersions.auto,
            size: widget.size,
          ),
        ),
        const SizedBox(height: 16),

        // Expiration info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Colors.green[700],
              ),
              const SizedBox(width: 8),
              Text(
                'Expires in: ${_getTimeRemaining()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build expired QR state
  Widget _buildExpiredState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.qr_code_2, size: 60, color: Colors.red),
        const SizedBox(height: 12),
        const Text(
          'QR Code Expired',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please refresh to get a new QR code',
          style: TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _handleRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Generate New QR'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
        ),
      ],
    );
  }
}
