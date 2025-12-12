import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../exceptions/api_exception.dart';
import '../utils/logger.dart';

/// QR Service - Handles all QR code operations with backend API
class QRService {
  static final QRService _instance = QRService._internal();
  static QRService get instance => _instance;

  final Logger _logger = Logger();
  String? _token;

  QRService._internal();

  /// Set authentication token
  void setToken(String? token) {
    _token = token;
  }

  /// Get authorization headers
  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  /// Generate QR token for a loan
  /// 
  /// Returns: {token, qr_data, expires_at, expires_in_seconds}
  Future<QRTokenResponse> generateQRToken({
    required String loanId,
    int durationMinutes = 15,
  }) async {
    try {
      _logger.info('Generating QR token for loan: $loanId');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/qr/generate'),
        headers: _headers,
        body: jsonEncode({
          'loan_id': loanId,
          'duration_minutes': durationMinutes,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('QR generation timeout'),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return QRTokenResponse.fromJson(data['data']);
        }
        throw ApiException(data['message'] ?? 'Failed to generate QR token');
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw ApiException(data['message'] ?? 'Invalid request');
      } else if (response.statusCode == 403) {
        throw ApiException('Unauthorized to generate QR for this loan');
      } else {
        throw ApiException('Failed to generate QR token: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      _logger.error('QR generation timeout: $e');
      throw ApiException('Request timeout. Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      _logger.error('QR generation error: $e');
      throw ApiException('Failed to generate QR token');
    }
  }

  /// Validate a scanned QR token
  /// 
  /// Returns: {loan, guarantor, qr_token}
  Future<QRValidationResponse> validateQRToken({
    required String qrToken,
    required String guarantorId,
  }) async {
    try {
      _logger.info('Validating QR token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/qr/validate'),
        headers: _headers,
        body: jsonEncode({
          'qr_token': qrToken,
          'guarantor_id': guarantorId,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('QR validation timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return QRValidationResponse.fromJson(data['data']);
        }
        throw ApiException(data['message'] ?? 'Validation failed');
      } else if (response.statusCode == 404) {
        throw ApiException('Invalid QR token');
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw ApiException(data['message'] ?? 'QR token is invalid or expired');
      } else if (response.statusCode == 403) {
        throw ApiException('User is not a guarantor for this loan');
      } else {
        throw ApiException('Validation failed: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      _logger.error('QR validation timeout: $e');
      throw ApiException('Request timeout. Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      _logger.error('QR validation error: $e');
      throw ApiException('Failed to validate QR token');
    }
  }

  /// Get QR tokens for a loan
  Future<List<QRTokenInfo>> getQRTokens(String loanId) async {
    try {
      _logger.info('Fetching QR tokens for loan: $loanId');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/qr/tokens/$loanId'),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Fetch QR tokens timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> tokens = data['data'] ?? [];
          return tokens
              .map((token) => QRTokenInfo.fromJson(token))
              .toList();
        }
        throw ApiException('Failed to fetch QR tokens');
      } else if (response.statusCode == 403) {
        throw ApiException('Unauthorized');
      } else {
        throw ApiException('Failed to fetch QR tokens: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      _logger.error('Fetch QR tokens timeout: $e');
      throw ApiException('Request timeout. Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      _logger.error('Fetch QR tokens error: $e');
      throw ApiException('Failed to fetch QR tokens');
    }
  }

  /// Get QR token status (public endpoint, no auth required)
  Future<QRStatusResponse> getQRStatus(String token) async {
    try {
      _logger.info('Checking QR status');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/qr/status/$token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('QR status check timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return QRStatusResponse.fromJson(data['data']);
        }
        throw ApiException('Failed to check QR status');
      } else if (response.statusCode == 404) {
        throw ApiException('QR token not found');
      } else {
        throw ApiException('Failed to check QR status: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      _logger.error('QR status check timeout: $e');
      throw ApiException('Request timeout. Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      _logger.error('QR status check error: $e');
      throw ApiException('Failed to check QR status');
    }
  }

  /// Revoke a QR token
  Future<bool> revokeQRToken(String qrToken) async {
    try {
      _logger.info('Revoking QR token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/qr/revoke'),
        headers: _headers,
        body: jsonEncode({
          'qr_token': qrToken,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('QR revoke timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else if (response.statusCode == 404) {
        throw ApiException('QR token not found');
      } else if (response.statusCode == 403) {
        throw ApiException('Unauthorized to revoke this token');
      } else {
        throw ApiException('Failed to revoke QR token: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      _logger.error('QR revoke timeout: $e');
      throw ApiException('Request timeout. Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      _logger.error('QR revoke error: $e');
      throw ApiException('Failed to revoke QR token');
    }
  }
}

/// QR Token Response Model
class QRTokenResponse {
  final String token;
  final Map<String, dynamic> qrData;
  final DateTime expiresAt;
  final int expiresInSeconds;

  QRTokenResponse({
    required this.token,
    required this.qrData,
    required this.expiresAt,
    required this.expiresInSeconds,
  });

  factory QRTokenResponse.fromJson(Map<String, dynamic> json) {
    return QRTokenResponse(
      token: json['token'] ?? '',
      qrData: json['qr_data'] ?? {},
      expiresAt: DateTime.parse(json['expires_at'] ?? DateTime.now().toIso8601String()),
      expiresInSeconds: json['expires_in_seconds'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'qr_data': qrData,
    'expires_at': expiresAt.toIso8601String(),
    'expires_in_seconds': expiresInSeconds,
  };
}

/// QR Validation Response Model
class QRValidationResponse {
  final Map<String, dynamic> loan;
  final Map<String, dynamic> guarantor;
  final Map<String, dynamic> qrToken;

  QRValidationResponse({
    required this.loan,
    required this.guarantor,
    required this.qrToken,
  });

  factory QRValidationResponse.fromJson(Map<String, dynamic> json) {
    return QRValidationResponse(
      loan: json['loan'] ?? {},
      guarantor: json['guarantor'] ?? {},
      qrToken: json['qr_token'] ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'loan': loan,
    'guarantor': guarantor,
    'qr_token': qrToken,
  };
}

/// QR Token Info Model
class QRTokenInfo {
  final int id;
  final String status;
  final DateTime expiresAt;
  final bool isExpired;
  final int? scannedBy;
  final DateTime? scannedAt;
  final DateTime createdAt;

  QRTokenInfo({
    required this.id,
    required this.status,
    required this.expiresAt,
    required this.isExpired,
    this.scannedBy,
    this.scannedAt,
    required this.createdAt,
  });

  factory QRTokenInfo.fromJson(Map<String, dynamic> json) {
    return QRTokenInfo(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'unknown',
      expiresAt: DateTime.parse(json['expires_at'] ?? DateTime.now().toIso8601String()),
      isExpired: json['is_expired'] ?? false,
      scannedBy: json['scanned_by'],
      scannedAt: json['scanned_at'] != null ? DateTime.parse(json['scanned_at']) : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'expires_at': expiresAt.toIso8601String(),
    'is_expired': isExpired,
    'scanned_by': scannedBy,
    'scanned_at': scannedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };
}

/// QR Status Response Model
class QRStatusResponse {
  final bool valid;
  final String token;
  final String loanId;
  final String status;
  final DateTime expiresAt;
  final bool isExpired;
  final int? scannedBy;
  final DateTime? scannedAt;

  QRStatusResponse({
    required this.valid,
    required this.token,
    required this.loanId,
    required this.status,
    required this.expiresAt,
    required this.isExpired,
    this.scannedBy,
    this.scannedAt,
  });

  factory QRStatusResponse.fromJson(Map<String, dynamic> json) {
    return QRStatusResponse(
      valid: json['valid'] ?? false,
      token: json['token'] ?? '',
      loanId: json['loan_id']?.toString() ?? '',
      status: json['status'] ?? 'unknown',
      expiresAt: DateTime.parse(json['expires_at'] ?? DateTime.now().toIso8601String()),
      isExpired: json['is_expired'] ?? false,
      scannedBy: json['scanned_by'],
      scannedAt: json['scanned_at'] != null ? DateTime.parse(json['scanned_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'valid': valid,
    'token': token,
    'loan_id': loanId,
    'status': status,
    'expires_at': expiresAt.toIso8601String(),
    'is_expired': isExpired,
    'scanned_by': scannedBy,
    'scanned_at': scannedAt?.toIso8601String(),
  };
}
