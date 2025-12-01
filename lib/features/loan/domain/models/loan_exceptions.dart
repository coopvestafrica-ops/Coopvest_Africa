/// Exception thrown when a loan rollover operation fails
class LoanRolloverException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  LoanRolloverException(this.message, {this.code, this.details});

  @override
  String toString() => 'LoanRolloverException: $message${code != null ? ' ($code)' : ''}';
}

/// Response from submitting a loan application
class LoanApplicationResponse {
  final String loanId;
  final DateTime submittedAt;
  final String? pendingValidation;

  LoanApplicationResponse({
    required this.loanId,
    required this.submittedAt,
    this.pendingValidation,
  });

  factory LoanApplicationResponse.fromMap(Map<String, dynamic> map) {
    return LoanApplicationResponse(
      loanId: map['loanId'] as String,
      submittedAt: DateTime.parse(map['submittedAt'] as String),
      pendingValidation: map['pendingValidation'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'loanId': loanId,
    'submittedAt': submittedAt.toIso8601String(),
    if (pendingValidation != null) 'pendingValidation': pendingValidation,
  };
}
