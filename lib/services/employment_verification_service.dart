import 'dart:convert';
import 'dart:math' show min, Random;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coopvest/models/employment_verification.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class EmploymentVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Helper method to extract text from document using cloud OCR service
  Future<Map<String, dynamic>> _extractTextFromDocument(String documentUrl) async {
    try {
      // Send to cloud OCR service
      final ocrResponse = await http.post(
        Uri.parse('https://api.coopvest.africa/ocr/process'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getOcrServiceApiKey()}',
        },
        body: json.encode({
          'document_url': documentUrl,
          'mime_type': _getMimeType(documentUrl),
        }),
      );

      if (ocrResponse.statusCode != 200) {
        throw Exception('OCR processing failed: ${ocrResponse.body}');
      }

      final result = json.decode(ocrResponse.body);
      
      return {
        'success': true,
        'text': result['text'],
        'blocks': result['blocks'] ?? [],
        'confidence': result['confidence'] ?? 0.0,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get MIME type from file extension
  String _getMimeType(String url) {
    final ext = path.extension(url).toLowerCase();
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get API key for OCR service
  Future<String> _getOcrServiceApiKey() async {
    try {
      final doc = await _firestore
          .collection('service_config')
          .doc('ocr')
          .get();

      if (!doc.exists) {
        throw Exception('OCR service configuration not found');
      }

      return doc.data()!['apiKey'] as String;
    } catch (e) {
      throw Exception('Failed to get OCR service API key: $e');
    }
  }

  /// Helper method to verify document authenticity
  Future<Map<String, dynamic>> _verifyDocumentAuthenticity(String documentUrl) async {
    try {
      // Make API call to document verification service
      final response = await http.post(
        Uri.parse('https://api.docverify.example.com/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'documentUrl': documentUrl}),
      );

      if (response.statusCode != 200) {
        throw Exception('Document verification failed');
      }

      final result = json.decode(response.body);
      return {
        'isAuthentic': result['isAuthentic'] ?? false,
        'confidence': result['confidence'] ?? 0.0,
        'verificationDetails': result['details'] ?? {},
      };
    } catch (e) {
      return {
        'isAuthentic': false,
        'error': e.toString(),
      };
    }
  }

  /// Helper method to process extracted text and identify relevant information
  Map<String, dynamic> _processExtractedText(List<Map<String, dynamic>> extractionResults) {
    final combinedText = extractionResults
        .where((result) => result['success'])
        .map((result) => result['text'].toString().toLowerCase())
        .join(' ');

    return {
      'companyName': _extractCompanyName(combinedText),
      'employeeId': _extractEmployeeId(combinedText),
      'position': _extractPosition(combinedText),
      'salary': _extractSalary(combinedText),
      'employmentDates': _extractEmploymentDates(combinedText),
    };
  }

  /// Helper method to compare extracted information with provided details
  Map<String, dynamic> _crossReferenceInformation(
    Map<String, dynamic> extractedInfo,
    EmploymentVerification providedInfo,
  ) {
    final matches = <String, bool>{};
    
    // Compare company names
    matches['companyName'] = _fuzzyMatch(
      extractedInfo['companyName']?.toString() ?? '',
      providedInfo.companyName,
    );

    // Compare employee IDs if available
    if (providedInfo.employeeId != null) {
      matches['employeeId'] = _fuzzyMatch(
        extractedInfo['employeeId']?.toString() ?? '',
        providedInfo.employeeId!,
      );
    }

    // Compare position/title
    matches['position'] = _fuzzyMatch(
      extractedInfo['position']?.toString() ?? '',
      providedInfo.position,
    );

    // Compare salary (with tolerance)
    final extractedSalary = double.tryParse(
      extractedInfo['salary']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0'
    ) ?? 0.0;
    
    matches['salary'] = (extractedSalary - providedInfo.monthlySalary).abs() <= 
      (providedInfo.monthlySalary * 0.1); // 10% tolerance

    return {
      'matches': matches.values.every((match) => match),
      'details': matches,
      'confidence': matches.values.where((match) => match).length / matches.length,
    };
  }

  /// Helper method for fuzzy string matching
  bool _fuzzyMatch(String str1, String str2, {double threshold = 0.8}) {
    str1 = str1.toLowerCase().trim();
    str2 = str2.toLowerCase().trim();

    if (str1 == str2) return true;
    if (str1.isEmpty || str2.isEmpty) return false;

    // Calculate Levenshtein distance
    final distance = _levenshteinDistance(str1, str2);
    final maxLength = str1.length > str2.length ? str1.length : str2.length;
    final similarity = 1 - (distance / maxLength);

    return similarity >= threshold;
  }

  /// Helper method to calculate Levenshtein distance
  int _levenshteinDistance(String str1, String str2) {
    final m = str1.length;
    final n = str2.length;
    final d = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (var i = 0; i <= m; i++) {
      d[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      d[0][j] = j;
    }

    for (var j = 1; j <= n; j++) {
      for (var i = 1; i <= m; i++) {
        if (str1[i - 1] == str2[j - 1]) {
          d[i][j] = d[i - 1][j - 1];
        } else {
          d[i][j] = [
            d[i - 1][j] + 1,      // deletion
            d[i][j - 1] + 1,      // insertion
            d[i - 1][j - 1] + 1,  // substitution
          ].reduce(min);
        }
      }
    }
    return d[m][n];
  }

  /// Helper methods to extract specific information from text
  String? _extractCompanyName(String text) {
    // Common patterns for company names in employment documents
    final patterns = [
      RegExp(r'(?:company|employer):\s*([^\n,]+)', caseSensitive: false),
      RegExp(r'(?:employed by|working for)\s+([^\n,]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  String? _extractEmployeeId(String text) {
    // Common patterns for employee IDs
    final patterns = [
      RegExp(r'(?:employee|staff|personnel)\s*(?:id|number):\s*([A-Z0-9-]+)', caseSensitive: false),
      RegExp(r'(?:id|number):\s*([A-Z0-9-]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  String? _extractPosition(String text) {
    // Common patterns for job positions
    final patterns = [
      RegExp(r'(?:position|title|role):\s*([^\n,]+)', caseSensitive: false),
      RegExp(r'(?:designated as|working as)\s+([^\n,]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  String? _extractSalary(String text) {
    // Common patterns for salary information
    final patterns = [
      RegExp(r'(?:salary|compensation|pay):\s*(?:NGN|₦)?\s*([0-9,.]+)', caseSensitive: false),
      RegExp(r'(?:NGN|₦)\s*([0-9,.]+)\s*(?:per|\/)\s*(?:month|monthly)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.replaceAll(RegExp(r'[,]'), '');
      }
    }
    return null;
  }

  Map<String, DateTime>? _extractEmploymentDates(String text) {
    // Common patterns for employment dates
    final startPattern = RegExp(
      r'(?:start(?:ed|ing)|commenc(?:ed|ing)|joined|from)?\s*(?:date|on)?\s*:?\s*(\d{1,2}[-/]\d{1,2}[-/]\d{4}|\d{4}[-/]\d{1,2}[-/]\d{1,2})',
      caseSensitive: false,
    );
    
    final endPattern = RegExp(
      r'(?:end(?:ed|ing)|terminat(?:ed|ing)|until|to)\s*(?:date|on)?\s*:?\s*(\d{1,2}[-/]\d{1,2}[-/]\d{4}|\d{4}[-/]\d{1,2}[-/]\d{1,2})',
      caseSensitive: false,
    );

    final startMatch = startPattern.firstMatch(text);
    final endMatch = endPattern.firstMatch(text);

    if (startMatch == null) return null;

    return {
      'startDate': _parseDate(startMatch.group(1)!),
      if (endMatch != null) 'endDate': _parseDate(endMatch.group(1)!),
    };
  }

  DateTime _parseDate(String dateStr) {
    // Handle various date formats
    final formats = [
      'dd-MM-yyyy',
      'dd/MM/yyyy',
      'yyyy-MM-dd',
      'yyyy/MM/dd',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parse(dateStr);
      } catch (_) {
        continue;
      }
    }

    throw FormatException('Invalid date format: $dateStr');
  }

  /// Upload and process employment verification documents
  Future<Map<String, dynamic>> submitVerification({
    required String userId,
    required String companyName,
    required String position,
    String? employeeId,
    String? companyEmail,
    required DateTime employmentStartDate,
    required double monthlySalary,
    required String employmentStatus,
    required List<String> documentUrls,
  }) async {
    try {
      // Validate inputs
      if (documentUrls.isEmpty) {
        throw Exception('At least one document is required for verification');
      }

      if (monthlySalary <= 0) {
        throw Exception('Monthly salary must be greater than 0');
      }

      if (employmentStartDate.isAfter(DateTime.now())) {
        throw Exception('Employment start date cannot be in the future');
      }

      if (companyEmail != null && !_isValidEmail(companyEmail)) {
        throw Exception('Invalid company email format');
      }

      // Check for existing verification
      final existingDoc = await _firestore
          .collection('employment_verifications')
          .doc(userId)
          .get();

      if (existingDoc.exists) {
        final existing = EmploymentVerification.fromJson(existingDoc.data()!);
        if (existing.verificationStatus == 'verified') {
          return {
            'success': false,
            'error': 'User already has a verified employment record',
            'existingVerification': existing.toJson(),
          };
        }
      }

      final verification = EmploymentVerification(
        userId: userId,
        companyName: companyName,
        employeeId: employeeId,
        position: position,
        companyEmail: companyEmail,
        employmentStartDate: employmentStartDate,
        monthlySalary: monthlySalary,
        employmentStatus: employmentStatus,
        documentUrls: documentUrls,
        verificationSteps: {
          'documents_uploaded': true,
          'employment_verified': false,
          'email_verified': false,
          'salary_verified': false,
        },
      );

      // Save verification request
      await _firestore
          .collection('employment_verifications')
          .doc(userId)
          .set(verification.toJson());

      // Start automatic document verification process
      verifyDocuments(userId, documentUrls).then((result) {
        if (result['success'] && result['verified']) {
          _firestore
              .collection('employment_verifications')
              .doc(userId)
              .update({
                'verificationSteps.employment_verified': true,
                'verificationSteps.salary_verified': true,
              });
        }
      });

      return {
        'success': true,
        'message': 'Verification process started. We will review your documents.',
        'verificationId': userId,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get verification status
  Future<EmploymentVerification?> getVerificationStatus(String userId) async {
    try {
      final doc = await _firestore
          .collection('employment_verifications')
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return EmploymentVerification.fromJson(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  /// Check if user is verified
  Future<bool> isVerifiedEmployee(String userId) async {
    try {
      final verification = await getVerificationStatus(userId);
      if (verification == null) return false;
      
      // Check if verification is expired (if it's older than 6 months)
      final verifiedAt = verification.verifiedAt;
      if (verifiedAt == null) return false;
      
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      if (verifiedAt.isBefore(sixMonthsAgo)) {
        // Mark verification as expired
        await _firestore
            .collection('employment_verifications')
            .doc(userId)
            .update({
              'verificationStatus': 'expired',
              'expiryReason': 'Verification is older than 6 months',
            });
        return false;
      }

      return verification.verificationStatus == 'verified';
    } catch (e) {
      return false;
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Process document verification
  Future<Map<String, dynamic>> verifyDocuments(
    String userId,
    List<String> documentUrls,
  ) async {
    try {
      // Use an OCR service to extract text from documents
      final textExtractionResults = await Future.wait(
        documentUrls.map((url) => _extractTextFromDocument(url))
      );

      // Verify document authenticity using ML model
      final authenticityScanResults = await Future.wait(
        documentUrls.map((url) => _verifyDocumentAuthenticity(url))
      );

      // Check if any documents failed authenticity check
      if (authenticityScanResults.any((result) => !result['isAuthentic'])) {
        return {
          'success': false,
          'verified': false,
          'reason': 'Document authenticity check failed',
        };
      }

      // Extract and validate information from OCR results
      final extractedInfo = _processExtractedText(textExtractionResults);
      
      // Cross-reference extracted info with provided details
      final verificationDoc = await _firestore
          .collection('employment_verifications')
          .doc(userId)
          .get();

      if (!verificationDoc.exists) {
        return {
          'success': false,
          'verified': false,
          'reason': 'Verification record not found',
        };
      }

      final providedInfo = EmploymentVerification.fromJson(verificationDoc.data()!);
      final matchResult = _crossReferenceInformation(extractedInfo, providedInfo);

      // Update verification status
      await _firestore
          .collection('employment_verifications')
          .doc(userId)
          .update({
            'verificationSteps.documents_verified': true,
            'extractedInfo': extractedInfo,
            'documentVerificationResult': matchResult,
          });

      return {
        'success': true,
        'verified': matchResult['matches'],
        'extractedInfo': extractedInfo,
        'matchResult': matchResult,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Send verification email to company email
  Future<Map<String, dynamic>> sendVerificationEmail(
    String userId,
    String companyEmail,
  ) async {
    try {
      // Get current verification
      final doc = await _firestore
          .collection('employment_verifications')
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw Exception('Verification not found');
      }

      final verification = EmploymentVerification.fromJson(doc.data()!);
      
      // Generate verification token
      final verificationToken = _generateVerificationToken(userId);
      
      // Create verification link
      final verificationLink = 'https://coopvest.africa/verify-employment?token=$verificationToken&userId=$userId';
      
      // Send email using email service
      final emailResult = await _sendEmail(
        to: companyEmail,
        subject: 'Employment Verification Request',
        template: 'employment_verification',
        params: {
          'companyName': verification.companyName,
          'position': verification.position,
          'employeeId': verification.employeeId ?? 'N/A',
          'verificationLink': verificationLink,
        },
      );

      if (!emailResult['success']) {
        throw Exception(emailResult['error']);
      }

      // Store verification token
      await _firestore.collection('verification_tokens').add({
        'userId': userId,
        'token': verificationToken,
        'type': 'employment',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'used': false,
      });

      // Update verification with email
      await _firestore
          .collection('employment_verifications')
          .doc(userId)
          .set(verification.copyWith(
            companyEmail: companyEmail,
            verificationSteps: {
              ...verification.verificationSteps,
              'verification_email_sent': true,
            },
          ).toJson());

      return {
        'success': true,
        'message': 'Verification email sent to $companyEmail',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Generate a secure verification token
  String _generateVerificationToken(String userId) {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Send email using email service
  Future<Map<String, dynamic>> _sendEmail({
    required String to,
    required String subject,
    required String template,
    required Map<String, dynamic> params,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.coopvest.africa/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getEmailServiceApiKey()}',
        },
        body: json.encode({
          'to': to,
          'subject': subject,
          'template': template,
          'params': params,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send email: ${response.body}');
      }

      return {
        'success': true,
        'messageId': json.decode(response.body)['messageId'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get API key for email service
  Future<String> _getEmailServiceApiKey() async {
    try {
      final doc = await _firestore
          .collection('service_config')
          .doc('email')
          .get();

      if (!doc.exists) {
        throw Exception('Email service configuration not found');
      }

      return doc.data()!['apiKey'] as String;
    } catch (e) {
      throw Exception('Failed to get email service API key: $e');
    }
  }

  /// Verify email through verification link
  Future<Map<String, dynamic>> verifyEmail(
    String userId,
    String token,
  ) async {
    try {
      // Verify token
      final tokenQuery = await _firestore
          .collection('verification_tokens')
          .where('userId', isEqualTo: userId)
          .where('token', isEqualTo: token)
          .where('type', isEqualTo: 'employment')
          .where('used', isEqualTo: false)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .limit(1)
          .get();

      if (tokenQuery.docs.isEmpty) {
        throw Exception('Invalid or expired verification token');
      }

      // Mark token as used
      await tokenQuery.docs.first.reference.update({
        'used': true,
        'usedAt': FieldValue.serverTimestamp(),
      });
      
      // Get current verification
      final doc = await _firestore
          .collection('employment_verifications')
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw Exception('Verification not found');
      }

      final verification = EmploymentVerification.fromJson(doc.data()!);

      // Update verification status
      await _firestore
          .collection('employment_verifications')
          .doc(userId)
          .set(verification.copyWith(
            isEmailVerified: true,
            verificationSteps: {
              ...verification.verificationSteps,
              'email_verified': true,
            },
          ).toJson());

      return {
        'success': true,
        'message': 'Email verified successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
