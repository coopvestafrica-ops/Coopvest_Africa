import 'dart:convert';

class QRDataEncoder {
  static String encodeLoanData(Map<String, dynamic> loanData) {
    final Map<String, dynamic> qrData = {
      'type': 'loan_guarantor',
      'data': {
        'loan_id': loanData['loan_id'],
        'amount': loanData['amount'],
        'duration': loanData['duration'],
        'timestamp': DateTime.now().toIso8601String(),
      }
    };
    
    return base64Url.encode(utf8.encode(json.encode(qrData)));
  }
  
  static Map<String, dynamic>? decodeLoanData(String encodedData) {
    try {
      final jsonString = utf8.decode(base64Url.decode(encodedData));
      final data = json.decode(jsonString);
      
      if (data['type'] != 'loan_guarantor') {
        return null;
      }
      
      return data['data'];
    } catch (e) {
      return null;
    }
  }
}
