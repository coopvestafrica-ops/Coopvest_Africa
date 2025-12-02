class LoanSubmissionResult {
  final String loanId;
  final String status;
  final String? message;
  final String? errorCode;
  final Map<String, dynamic>? data;

  const LoanSubmissionResult({
    required this.loanId,
    required this.status,
    this.message,
    this.errorCode,
    this.data,
  });

  factory LoanSubmissionResult.success({
    required String loanId,
    Map<String, dynamic>? data,
  }) {
    return LoanSubmissionResult(
      loanId: loanId,
      status: 'success',
      data: data,
    );
  }

  factory LoanSubmissionResult.failure({
    String message = 'Failed to submit loan application',
    String? errorCode,
  }) {
    return LoanSubmissionResult(
      loanId: '',  // Empty ID for failures
      status: 'failure',
      message: message,
      errorCode: errorCode,
    );
  }

  factory LoanSubmissionResult.fromMap(Map<String, dynamic> map) {
    return LoanSubmissionResult(
      loanId: map['loanId'] as String,
      status: map['status'] as String,
      message: map['message'] as String?,
      errorCode: map['errorCode'] as String?,
      data: map['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'loanId': loanId,
      'status': status,
      if (message != null) 'message': message,
      if (errorCode != null) 'errorCode': errorCode,
      if (data != null) 'data': data,
    };
  }

  bool get isSuccess => status == 'success';

  @override
  String toString() => 'LoanSubmissionResult(loanId: $loanId, status: $status, message: $message, errorCode: $errorCode)';
}
