class LoanGuarantor {
  final String id;
  final String userId;
  final String fullName;
  final String membershipId;
  final double guaranteedAmount;
  final DateTime guaranteedAt;
  final String status;
  final bool isEligible;
  final double? maxAmount;
  final Map<String, dynamic>? metrics;
  final DateTime? lastValidated;
  final int validationAttempts;

  const LoanGuarantor({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.membershipId,
    required this.guaranteedAmount,
    required this.guaranteedAt,
    required this.status,
    this.isEligible = true,
    this.maxAmount,
    this.metrics,
    this.lastValidated,
    this.validationAttempts = 0,
  });

  factory LoanGuarantor.fromJson(Map<String, dynamic> json) {
    return LoanGuarantor(
      id: json['id'] as String,
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      membershipId: json['membershipId'] as String,
      guaranteedAmount: (json['guaranteedAmount'] as num).toDouble(),
      guaranteedAt: DateTime.parse(json['guaranteedAt'] as String),
      status: json['status'] as String,
      isEligible: json['isEligible'] as bool? ?? true,
      maxAmount: json['maxAmount'] != null ? (json['maxAmount'] as num).toDouble() : null,
      metrics: json['metrics'] as Map<String, dynamic>?,
      lastValidated: json['lastValidated'] != null 
          ? DateTime.parse(json['lastValidated'] as String) 
          : null,
      validationAttempts: json['validationAttempts'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'membershipId': membershipId,
      'guaranteedAmount': guaranteedAmount,
      'guaranteedAt': guaranteedAt.toIso8601String(),
      'status': status,
      'isEligible': isEligible,
      if (maxAmount != null) 'maxAmount': maxAmount,
      if (metrics != null) 'metrics': metrics,
      if (lastValidated != null) 'lastValidated': lastValidated!.toIso8601String(),
      'validationAttempts': validationAttempts,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'guarantorId': userId,
      'fullName': fullName,
      'amount': guaranteedAmount,
      'status': status,
      'isEligible': isEligible,
      'approvedRollover': false,
      if (lastValidated != null) 'lastValidated': lastValidated!.toIso8601String(),
      'validationAttempts': validationAttempts,
    };
  }

  LoanGuarantor copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? membershipId,
    double? guaranteedAmount,
    DateTime? guaranteedAt,
    String? status,
    bool? isEligible,
    double? maxAmount,
    Map<String, dynamic>? metrics,
    DateTime? lastValidated,
    int? validationAttempts,
  }) {
    return LoanGuarantor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      membershipId: membershipId ?? this.membershipId,
      guaranteedAmount: guaranteedAmount ?? this.guaranteedAmount,
      guaranteedAt: guaranteedAt ?? this.guaranteedAt,
      status: status ?? this.status,
      isEligible: isEligible ?? this.isEligible,
      maxAmount: maxAmount ?? this.maxAmount,
      metrics: metrics ?? this.metrics,
      lastValidated: lastValidated ?? this.lastValidated,
      validationAttempts: validationAttempts ?? this.validationAttempts,
    );
  }
}
