class LoanApplication {
  final String? id;
  final String userId;
  final double amount;
  final int tenureMonths;
  final String status;
  final Map<String, dynamic> employment;
  final Map<String, dynamic> financials;
  final List<Map<String, dynamic>> guarantors;
  final Map<String, String>? documents;
  final DateTime? createdAt;
  final DateTime? lastUpdated;

  LoanApplication({
    this.id,
    required this.userId,
    required this.amount,
    required this.tenureMonths,
    required this.status,
    required this.employment,
    required this.financials,
    required this.guarantors,
    this.documents,
    this.createdAt,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'tenureMonths': tenureMonths,
      'status': status,
      'employment': employment,
      'financials': financials,
      'guarantors': guarantors,
      'documents': documents,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
    };
  }

  factory LoanApplication.fromMap(Map<String, dynamic> map) {
    return LoanApplication(
      id: map['id'] as String?,
      userId: map['userId'] as String,
      amount: (map['amount'] as num).toDouble(),
      tenureMonths: (map['tenureMonths'] as num).toInt(),
      status: map['status'] as String,
      employment: Map<String, dynamic>.from(map['employment']),
      financials: Map<String, dynamic>.from(map['financials']),
      guarantors: List<Map<String, dynamic>>.from(map['guarantors']),
      documents: map['documents'] != null ? Map<String, String>.from(map['documents']) : null,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as DateTime) : null,
      lastUpdated: map['lastUpdated'] != null ? (map['lastUpdated'] as DateTime) : null,
    );
  }
}
