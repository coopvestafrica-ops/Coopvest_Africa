class LoanProjection {
  final double amount;
  final int duration;
  final double interestRate;
  final String interestType;
  final double totalRepaymentAmount;
  final double totalInterestAmount;
  final double monthlyRepaymentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final List<Map<String, dynamic>> repaymentSchedule;

  LoanProjection({
    required this.amount,
    required this.duration,
    required this.interestRate,
    required this.interestType,
    required this.totalRepaymentAmount,
    required this.totalInterestAmount,
    required this.monthlyRepaymentAmount,
    required this.startDate,
    required this.endDate,
    required this.repaymentSchedule,
  });

  factory LoanProjection.fromMap(Map<String, dynamic> map) {
    return LoanProjection(
      amount: (map['amount'] as num).toDouble(),
      duration: map['duration'] as int,
      interestRate: (map['interestRate'] as num).toDouble(),
      interestType: map['interestType'] as String,
      totalRepaymentAmount: (map['totalRepaymentAmount'] as num).toDouble(),
      totalInterestAmount: (map['totalInterestAmount'] as num).toDouble(),
      monthlyRepaymentAmount: (map['monthlyRepaymentAmount'] as num).toDouble(),
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      repaymentSchedule: List<Map<String, dynamic>>.from(
        (map['repaymentSchedule'] as List).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'duration': duration,
      'interestRate': interestRate,
      'interestType': interestType,
      'totalRepaymentAmount': totalRepaymentAmount,
      'totalInterestAmount': totalInterestAmount,
      'monthlyRepaymentAmount': monthlyRepaymentAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'repaymentSchedule': repaymentSchedule,
    };
  }
}
