class LoanEligibility {
  final bool isEligible;
  final String? message;
  final double? maxEligibleAmount;
  final int? maxEligibleDuration;
  final List<String>? requiredDocuments;
  final Map<String, dynamic>? requirements;
  final Map<String, dynamic>? additionalInfo;

  LoanEligibility({
    required this.isEligible,
    this.message,
    this.maxEligibleAmount,
    this.maxEligibleDuration,
    this.requiredDocuments,
    this.requirements,
    this.additionalInfo,
  });

  factory LoanEligibility.fromMap(Map<String, dynamic> map) {
    return LoanEligibility(
      isEligible: map['isEligible'] as bool,
      message: map['message'] as String?,
      maxEligibleAmount: map['maxEligibleAmount'] != null
          ? (map['maxEligibleAmount'] as num).toDouble()
          : null,
      maxEligibleDuration: map['maxEligibleDuration'] as int?,
      requiredDocuments: map['requiredDocuments'] != null
          ? List<String>.from(map['requiredDocuments'] as List)
          : null,
      requirements: map['requirements'] != null
          ? Map<String, dynamic>.from(map['requirements'] as Map)
          : null,
      additionalInfo: map['additionalInfo'] != null
          ? Map<String, dynamic>.from(map['additionalInfo'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEligible': isEligible,
      'message': message,
      'maxEligibleAmount': maxEligibleAmount,
      'maxEligibleDuration': maxEligibleDuration,
      'requiredDocuments': requiredDocuments,
      'requirements': requirements,
      'additionalInfo': additionalInfo,
    }..removeWhere((key, value) => value == null);
  }
}
