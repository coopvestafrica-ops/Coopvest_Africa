class TerminationStatus {
  final String status;
  final DateTime requestDate;
  final DateTime effectiveDate;
  final String reason;

  TerminationStatus({
    required this.status,
    required this.requestDate,
    required this.effectiveDate,
    required this.reason,
  });

  factory TerminationStatus.fromJson(Map<String, dynamic> json) {
    return TerminationStatus(
      status: json['status'] as String,
      requestDate: DateTime.parse(json['requestDate'] as String),
      effectiveDate: DateTime.parse(json['effectiveDate'] as String),
      reason: json['reason'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'requestDate': requestDate.toIso8601String(),
    'effectiveDate': effectiveDate.toIso8601String(),
    'reason': reason,
  };
}
