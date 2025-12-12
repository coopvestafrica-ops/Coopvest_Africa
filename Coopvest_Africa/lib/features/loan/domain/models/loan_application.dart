import 'loan_guarantor.dart';

class LoanApplication {
  final String? id;
  final String userId;
  final String type;
  final double loanAmount;
  final int tenureMonths;
  final String purpose;
  final double monthlySavings;
  final String? status;
  final List<LoanGuarantor>? guarantors;
  final DateTime? submittedAt;
  final DateTime? updatedAt;

  LoanApplication({
    this.id,
    required this.userId,
    required this.type,
    required this.loanAmount,
    required this.tenureMonths,
    required this.purpose,
    required this.monthlySavings,
    this.guarantors,
    this.status = 'pending',
    this.submittedAt,
    this.updatedAt,
  });

  factory LoanApplication.fromJson(Map<String, dynamic> json) {
    return LoanApplication(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      type: json['type'] as String,
      loanAmount: (json['loanAmount'] as num).toDouble(),
      tenureMonths: (json['tenureMonths'] as num).toInt(),
      purpose: json['purpose'] as String,
      monthlySavings: (json['monthlySavings'] as num).toDouble(),
      guarantors: json['guarantors'] != null
          ? (json['guarantors'] as List)
              .map((g) => LoanGuarantor.fromJson(g as Map<String, dynamic>))
              .toList()
          : null,
      status: json['status'] as String?,
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'type': type,
      'loanAmount': loanAmount,
      'tenureMonths': tenureMonths,
      'purpose': purpose,
      'monthlySavings': monthlySavings,
      if (guarantors != null) 'guarantors': guarantors!.map((g) => g.toJson()).toList(),
      if (status != null) 'status': status,
      if (submittedAt != null) 'submittedAt': submittedAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  LoanApplication copyWith({
    String? id,
    String? userId,
    String? type,
    double? loanAmount,
    int? tenureMonths,
    String? purpose,
    double? monthlySavings,
    List<LoanGuarantor>? guarantors,
    String? status,
    DateTime? submittedAt,
    DateTime? updatedAt,
  }) {
    return LoanApplication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      loanAmount: loanAmount ?? this.loanAmount,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      purpose: purpose ?? this.purpose,
      monthlySavings: monthlySavings ?? this.monthlySavings,
      guarantors: guarantors ?? this.guarantors,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LoanApplicationResponse {
  final String loanId;

  LoanApplicationResponse({
    required this.loanId,
  });

  factory LoanApplicationResponse.fromJson(Map<String, dynamic> json) {
    return LoanApplicationResponse(
      loanId: json['loan_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loan_id': loanId,
    };
  }
}
