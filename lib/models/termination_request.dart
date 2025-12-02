class TerminationStatus {
  final String status; // pending, processing, cancelled, completed
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
      status: json['status'],
      requestDate: DateTime.parse(json['request_date']),
      effectiveDate: DateTime.parse(json['effective_date']),
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'request_date': requestDate.toIso8601String(),
      'effective_date': effectiveDate.toIso8601String(),
      'reason': reason,
    };
  }
}
