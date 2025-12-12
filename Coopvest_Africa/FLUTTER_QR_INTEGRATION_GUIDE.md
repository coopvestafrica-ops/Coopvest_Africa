# Flutter QR Code Integration Guide

## Overview

This guide explains how to integrate the new QR code API with your Flutter app. The QR code system now uses backend API endpoints for secure token generation, validation, and management.

---

## Files Created/Modified

### New Files
- `lib/core/services/qr_service.dart` - QR Service with backend API integration
- `lib/features/loan/presentation/widgets/qr_code_display_updated.dart` - Updated QR display widget

### Files to Update
- `lib/core/config/api_config.dart` - Add QR endpoints
- `lib/core/services/api_service.dart` - Add QR methods
- `lib/features/loan/presentation/screens/loan_qr_confirmation_screen.dart` - Use new QR service
- `lib/features/loan/presentation/widgets/guarantor_qr_code.dart` - Use new QR service

---

## Step 1: Update API Config

Edit `lib/core/config/api_config.dart` and add QR endpoints:

```dart
class ApiConfig {
  static const String baseUrl = 'https://api.coopvest.africa/v1';
  
  // ... existing endpoints ...
  
  // QR Code endpoints
  static const String qrGenerate = '/qr/generate';
  static const String qrValidate = '/qr/validate';
  static const String qrTokens = '/qr/tokens';
  static const String qrStatus = '/qr/status';
  static const String qrRevoke = '/qr/revoke';
}
```

---

## Step 2: Initialize QR Service

In your main app initialization (e.g., `main.dart` or `app.dart`):

```dart
import 'package:coopvest/core/services/qr_service.dart';
import 'package:coopvest/core/services/auth_service.dart';

void main() {
  // Initialize services
  final authService = AuthService.instance;
  final qrService = QRService.instance;
  
  // Set token when user logs in
  authService.onTokenChanged.listen((token) {
    qrService.setToken(token);
  });
  
  runApp(const MyApp());
}
```

---

## Step 3: Update Loan QR Confirmation Screen

Replace the old implementation with the new one:

```dart
import 'package:coopvest/features/loan/presentation/widgets/qr_code_display_updated.dart';

class LoanQRConfirmationScreen extends StatelessWidget {
  final String loanId;
  
  const LoanQRConfirmationScreen({
    required this.loanId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan QR Code'),
      ),
      body: QRCodeDisplayUpdated(
        loanId: loanId,
        label: 'Share this QR code with your guarantors',
        onRefresh: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR code refreshed')),
          );
        },
        onError: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to generate QR code')),
          );
        },
      ),
    );
  }
}
```

---

## Step 4: Update Guarantor QR Code Widget

Replace the old implementation:

```dart
import 'package:coopvest/core/services/qr_service.dart';

class GuarantorQRCodeUpdated extends StatefulWidget {
  final String loanId;

  const GuarantorQRCodeUpdated({
    super.key,
    required this.loanId,
  });

  @override
  State<GuarantorQRCodeUpdated> createState() => _GuarantorQRCodeUpdatedState();
}

class _GuarantorQRCodeUpdatedState extends State<GuarantorQRCodeUpdated> {
  late QRService _qrService;

  @override
  void initState() {
    super.initState();
    _qrService = QRService.instance;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan to Guarantee',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Have your guarantors scan this QR code to approve the loan',
            ),
            const SizedBox(height: 16),
            QRCodeDisplayUpdated(
              loanId: widget.loanId,
              size: 200,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Step 5: Implement QR Scanning

Create a new screen for scanning QR codes:

```dart
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:coopvest/core/services/qr_service.dart';

class QRScannerScreen extends StatefulWidget {
  final String guarantorId;

  const QRScannerScreen({
    required this.guarantorId,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late QRService _qrService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _qrService = QRService.instance;
  }

  Future<void> _handleQRDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        await _validateQRCode(barcode.rawValue!);
      }
    }
  }

  Future<void> _validateQRCode(String qrToken) async {
    setState(() => _isProcessing = true);

    try {
      final result = await _qrService.validateQRToken(
        qrToken: qrToken,
        guarantorId: widget.guarantorId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR validated successfully!')),
        );
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleQRDetect,
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## Step 6: Add QR Methods to API Service

Update `lib/core/services/api_service.dart`:

```dart
// Add these methods to ApiService class

/// Generate QR token for a loan
Future<Map<String, dynamic>> generateQRToken(String loanId, {int durationMinutes = 15}) async {
  return post<Map<String, dynamic>>(
    '/qr/generate',
    {
      'loan_id': loanId,
      'duration_minutes': durationMinutes,
    },
    (json) => json,
  );
}

/// Validate QR token
Future<Map<String, dynamic>> validateQRToken(String qrToken, String guarantorId) async {
  return post<Map<String, dynamic>>(
    '/qr/validate',
    {
      'qr_token': qrToken,
      'guarantor_id': guarantorId,
    },
    (json) => json,
  );
}

/// Get QR tokens for a loan
Future<List<Map<String, dynamic>>> getQRTokens(String loanId) async {
  return getList<Map<String, dynamic>>(
    '/qr/tokens/$loanId',
    (json) => json,
  );
}

/// Get QR status
Future<Map<String, dynamic>> getQRStatus(String token) async {
  return get<Map<String, dynamic>>(
    '/qr/status/$token',
    (json) => json,
  );
}

/// Revoke QR token
Future<bool> revokeQRToken(String qrToken) async {
  final result = await post<Map<String, dynamic>>(
    '/qr/revoke',
    {'qr_token': qrToken},
    (json) => json,
  );
  return result['success'] == true;
}
```

---

## Step 7: Update Pubspec Dependencies

Ensure you have the required dependencies in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.1
  qr_flutter: ^4.1.0
  mobile_scanner: ^7.0.1
  # ... other dependencies
```

Run:
```bash
flutter pub get
```

---

## Usage Examples

### Generate QR Code

```dart
final qrService = QRService.instance;

try {
  final response = await qrService.generateQRToken(
    loanId: '123',
    durationMinutes: 15,
  );
  
  print('QR Token: ${response.token}');
  print('Expires at: ${response.expiresAt}');
} catch (e) {
  print('Error: $e');
}
```

### Validate QR Code

```dart
try {
  final result = await qrService.validateQRToken(
    qrToken: 'QR_abc123...',
    guarantorId: '456',
  );
  
  print('Loan: ${result.loan}');
  print('Guarantor: ${result.guarantor}');
} catch (e) {
  print('Error: $e');
}
```

### Get QR Status

```dart
try {
  final status = await qrService.getQRStatus('QR_abc123...');
  
  print('Valid: ${status.valid}');
  print('Status: ${status.status}');
  print('Expires at: ${status.expiresAt}');
} catch (e) {
  print('Error: $e');
}
```

### Revoke QR Code

```dart
try {
  final success = await qrService.revokeQRToken('QR_abc123...');
  
  if (success) {
    print('QR code revoked');
  }
} catch (e) {
  print('Error: $e');
}
```

---

## Error Handling

The QR Service throws `ApiException` for all errors:

```dart
import 'package:coopvest/core/exceptions/api_exception.dart';

try {
  await qrService.generateQRToken(loanId: '123');
} on ApiException catch (e) {
  print('API Error: ${e.message}');
  // Handle specific error
  if (e.message.contains('expired')) {
    // Handle expired token
  }
} catch (e) {
  print('Unknown error: $e');
}
```

---

## Testing

### Unit Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coopvest/core/services/qr_service.dart';

void main() {
  group('QRService', () {
    late QRService qrService;

    setUp(() {
      qrService = QRService.instance;
      qrService.setToken('test_token');
    });

    test('generateQRToken returns valid response', () async {
      final response = await qrService.generateQRToken(loanId: '1');
      
      expect(response.token, isNotEmpty);
      expect(response.expiresAt, isNotNull);
    });

    test('validateQRToken validates correctly', () async {
      final result = await qrService.validateQRToken(
        qrToken: 'QR_test',
        guarantorId: '2',
      );
      
      expect(result.loan, isNotEmpty);
      expect(result.guarantor, isNotEmpty);
    });
  });
}
```

---

## Troubleshooting

### Issue: "Unauthorized to generate QR"

**Solution:**
- Ensure user is authenticated
- Check token is set in QRService
- Verify user owns the loan

### Issue: "QR token is expired"

**Solution:**
- Generate a new QR token
- Check server time synchronization
- Increase duration_minutes parameter

### Issue: "User is not a guarantor"

**Solution:**
- Ensure guarantor is added to loan first
- Check guarantor status is 'pending'
- Verify guarantor user_id

### Issue: Network timeout

**Solution:**
- Check internet connection
- Verify API server is running
- Increase timeout duration
- Check firewall/proxy settings

---

## Migration from Old System

If you're migrating from the old local QR generation:

1. **Old Code:**
```dart
// Old way - local generation
final qrData = json.encode({
  'loan_id': loanData['loan_id'],
  'amount': loanData['amount'],
});
```

2. **New Code:**
```dart
// New way - backend generation
final response = await qrService.generateQRToken(
  loanId: loanData['loan_id'],
);
```

---

## Performance Tips

1. **Cache QR Tokens**
   - Store generated tokens locally
   - Reuse tokens within expiration window
   - Reduce API calls

2. **Batch Operations**
   - Generate multiple QR codes in parallel
   - Use Future.wait() for concurrent requests

3. **Error Recovery**
   - Implement retry logic with exponential backoff
   - Cache failed requests
   - Provide offline fallback

---

## Security Best Practices

1. **Token Storage**
   - Never log tokens
   - Use secure storage for sensitive data
   - Clear tokens on logout

2. **Validation**
   - Always validate on backend
   - Check token expiration
   - Verify user permissions

3. **Rate Limiting**
   - Respect API rate limits
   - Implement client-side throttling
   - Handle 429 responses gracefully

---

## Next Steps

1. ✅ Flutter QR Service created
2. ⏳ Update all screens to use new service
3. ⏳ Implement QR scanning
4. ⏳ Add real-time sync
5. ⏳ Deploy to production

---

**Last Updated:** December 9, 2024  
**Status:** Ready for Implementation
