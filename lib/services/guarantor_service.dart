import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/guarantor.dart';
import '../models/guarantor_invitation.dart';
import '../models/guarantor_verification.dart';

class GuarantorService {
  final String baseUrl = 'https://api.coopvest.africa'; // Replace with your actual API URL
  
  /// Get auth token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Get auth headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ==================== GUARANTOR MANAGEMENT ====================
  
  /// Get all guarantors for a specific loan
  Future<List<Guarantor>> getGuarantorsForLoan(String loanId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/loans/$loanId/guarantors'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> guarantorsList = data['guarantors'] ?? data['data'] ?? [];
        return guarantorsList.map((g) => Guarantor.fromJson(g)).toList();
      } else {
        throw Exception('Failed to fetch guarantors');
      }
    } catch (e) {
      throw Exception('Error fetching guarantors: $e');
    }
  }

  /// Get a specific guarantor by ID
  Future<Guarantor> getGuarantorById(String guarantorId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/guarantors/$guarantorId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Guarantor.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Guarantor not found');
      }
    } catch (e) {
      throw Exception('Error fetching guarantor: $e');
    }
  }

  /// Create/invite a guarantor for a loan
  Future<Guarantor> inviteGuarantor(
    String loanId, {
    required String guarantorEmail,
    String? guarantorPhone,
    String? guarantorName,
    required String relationship,
    bool employmentVerificationRequired = false,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/loans/$loanId/guarantors'),
        headers: headers,
        body: json.encode({
          'guarantor_email': guarantorEmail,
          'guarantor_phone': guarantorPhone,
          'guarantor_name': guarantorName,
          'relationship': relationship,
          'employment_verification_required': employmentVerificationRequired,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return Guarantor.fromJson(data['data'] ?? data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to invite guarantor');
      }
    } catch (e) {
      throw Exception('Error inviting guarantor: $e');
    }
  }

  /// Delete/remove a guarantor
  Future<void> removeGuarantor(String loanId, String guarantorId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/loans/$loanId/guarantors/$guarantorId'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to remove guarantor');
      }
    } catch (e) {
      throw Exception('Error removing guarantor: $e');
    }
  }

  // ==================== GUARANTOR INVITATIONS ====================

  /// Get pending guarantor invitations for the current user
  Future<List<GuarantorInvitation>> getPendingInvitations() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/guarantor/pending-invitations'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> invitations = data['invitations'] ?? data['data'] ?? [];
        return invitations.map((inv) => GuarantorInvitation.fromJson(inv)).toList();
      } else {
        throw Exception('Failed to fetch invitations');
      }
    } catch (e) {
      throw Exception('Error fetching invitations: $e');
    }
  }

  /// Get invitation details by token (public endpoint)
  Future<GuarantorInvitation> getInvitationByToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/guarantor-invitations/$token'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GuarantorInvitation.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Invitation not found or invalid');
      }
    } catch (e) {
      throw Exception('Error fetching invitation: $e');
    }
  }

  /// Accept a guarantor invitation
  Future<Guarantor> acceptInvitation(String token) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/guarantor-invitations/$token/accept'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Guarantor.fromJson(data['guarantor'] ?? data['data'] ?? data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to accept invitation');
      }
    } catch (e) {
      throw Exception('Error accepting invitation: $e');
    }
  }

  /// Decline a guarantor invitation
  Future<void> declineInvitation(String token, {String? reason}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/guarantor-invitations/$token/decline'),
        headers: headers,
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to decline invitation');
      }
    } catch (e) {
      throw Exception('Error declining invitation: $e');
    }
  }

  // ==================== GUARANTOR VERIFICATION ====================

  /// Get verification status for a guarantor
  Future<GuarantorVerification> getVerificationStatus(String guarantorId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/guarantors/$guarantorId/verification'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GuarantorVerification.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Verification status not found');
      }
    } catch (e) {
      throw Exception('Error fetching verification status: $e');
    }
  }

  /// Submit verification documents for a guarantor
  Future<GuarantorVerification> submitVerificationDocuments(
    String guarantorId,
    List<String> documentPaths, // File paths
  ) async {
    try {
      final headers = await _getHeaders();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/guarantors/$guarantorId/verification'),
      );

      // Add auth header
      request.headers.addAll({'Authorization': headers['Authorization']!});

      // Add files
      for (var i = 0; i < documentPaths.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'documents[]',
            documentPaths[i],
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return GuarantorVerification.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to submit verification documents');
      }
    } catch (e) {
      throw Exception('Error submitting verification documents: $e');
    }
  }

  /// Upload employment verification document
  Future<void> uploadEmploymentVerification(
    String guarantorId,
    String documentPath,
  ) async {
    try {
      final headers = await _getHeaders();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/guarantors/$guarantorId/employment-verification'),
      );

      request.headers.addAll({'Authorization': headers['Authorization']!});
      request.files.add(
        await http.MultipartFile.fromPath('document', documentPath),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to upload employment verification');
      }
    } catch (e) {
      throw Exception('Error uploading employment verification: $e');
    }
  }

  // ==================== LEGACY METHODS (Keep for compatibility) ====================

  Future<Map<String, dynamic>> validateGuarantorEligibility(String loanId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/loan-guarantee/validate/$loanId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to validate guarantor eligibility');
    }
  }

  Future<Map<String, dynamic>> getLoanDetails(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/loan-guarantee/details/$code'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch loan details');
    }
  }

  Future<void> confirmGuarantee(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/loan-guarantee/confirm'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'guarantee_code': code,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to confirm guarantee');
    }
  }

  Future<void> revokeGuarantee(String loanId, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/loan-guarantee/revoke/$loanId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'reason': reason,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to revoke guarantee');
    }
  }

  Future<Map<String, dynamic>> getMyGuarantees() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/loan-guarantee/my-guarantees'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch guarantees');
    }
  }
}
