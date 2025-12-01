class LoanProduct {
  final String id;
  final String name;
  final String description;
  final double minAmount;
  final double maxAmount;
  final int minDuration;
  final int maxDuration;
  final double interestRate;
  final String interestType;
  final List<String> requiredDocuments;
  final Map<String, dynamic> requirements;
  final String status;

  LoanProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.minAmount,
    required this.maxAmount,
    required this.minDuration,
    required this.maxDuration,
    required this.interestRate,
    required this.interestType,
    required this.requiredDocuments,
    required this.requirements,
    required this.status,
  });

  factory LoanProduct.fromMap(Map<String, dynamic> map) {
    return LoanProduct(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      minAmount: (map['minAmount'] as num).toDouble(),
      maxAmount: (map['maxAmount'] as num).toDouble(),
      minDuration: map['minDuration'] as int,
      maxDuration: map['maxDuration'] as int,
      interestRate: (map['interestRate'] as num).toDouble(),
      interestType: map['interestType'] as String,
      requiredDocuments: List<String>.from(map['requiredDocuments'] as List),
      requirements: Map<String, dynamic>.from(map['requirements'] as Map),
      status: map['status'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'minDuration': minDuration,
      'maxDuration': maxDuration,
      'interestRate': interestRate,
      'interestType': interestType,
      'requiredDocuments': requiredDocuments,
      'requirements': requirements,
      'status': status,
    };
  }
}
