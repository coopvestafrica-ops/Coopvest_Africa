import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class LoanQRGenerator {
  static Widget generateQRCode(Map<String, dynamic> loanData, {double size = 200.0}) {
    // Create a unique code that includes loan ID and timestamp
    final qrData = json.encode({
      'loan_id': loanData['loan_id'],
      'amount': loanData['amount'],
      'applicant_id': loanData['applicant_id'],
      'timestamp': DateTime.now().toIso8601String(),
    });

    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
    );
  }

  static String generateGuarantorCode(String loanId) {
    // Generate a human-readable code format: CVL-XXXXX-YY
    // where XXXXX is the loan ID and YY is a checksum
    final String numericId = loanId.replaceAll(RegExp(r'[^0-9]'), '');
    final String paddedId = numericId.padLeft(5, '0');
    final int checksum = _calculateChecksum(paddedId);
    return 'CVL-$paddedId-${checksum.toString().padLeft(2, '0')}';
  }

  static int _calculateChecksum(String input) {
    int sum = 0;
    for (int i = 0; i < input.length; i++) {
      sum += int.parse(input[i]) * (i + 1);
    }
    return sum % 100;
  }
}
