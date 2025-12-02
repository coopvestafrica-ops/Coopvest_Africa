/// Represents the eligibility status for a loan rollover
class RolloverEligibility {
  /// Whether the loan is eligible for rollover
  final bool isEligible;

  /// Message explaining the eligibility status
  final String message;

  /// Maximum amount allowed for the new loan
  final double? maxAmount;

  /// Available tenure options in months
  final List<int>? availableTenures;

  /// Additional requirements or details about eligibility
  final Map<String, dynamic>? requirements;

  const RolloverEligibility({
    required this.isEligible,
    required this.message,
    this.maxAmount,
    this.availableTenures,
    this.requirements,
  });

  factory RolloverEligibility.fromJson(Map<String, dynamic> json) {
    return RolloverEligibility(
      isEligible: json['isEligible'] as bool,
      message: json['message'] as String? ?? json['reason'] as String? ?? '',
      maxAmount: json['maxAmount'] as double?,
      availableTenures: json['availableTenures'] != null 
        ? List<int>.from(json['availableTenures'] as List)
        : null,
      requirements: json['requirements'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEligible': isEligible,
      'message': message,
      'maxAmount': maxAmount,
      'availableTenures': availableTenures,
      'requirements': requirements,
    }..removeWhere((_, v) => v == null);
  }

  @override
  String toString() {
    return 'RolloverEligibility(isEligible: $isEligible, message: $message, '
      'maxAmount: $maxAmount, availableTenures: $availableTenures, '
      'requirements: $requirements)';
  }
}
