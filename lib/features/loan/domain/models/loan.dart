import 'package:equatable/equatable.dart';

class Document extends Equatable {
  final String id;
  final String name;
  final String type;
  final String url;
  final DateTime uploadedAt;
  final String status;
  final Map<String, dynamic>? metadata;

  const Document({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.uploadedAt,
    required this.status,
    this.metadata,
  });

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      url: map['url'],
      uploadedAt: DateTime.parse(map['uploadedAt']),
      status: map['status'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'url': url,
      'uploadedAt': uploadedAt.toIso8601String(),
      'status': status,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        url,
        uploadedAt,
        status,
        metadata,
      ];
}

class Transaction extends Equatable {
  final String id;
  final double amount;
  final String type;
  final String status;
  final DateTime date;
  final String reference;
  final Map<String, dynamic>? metadata;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    required this.date,
    required this.reference,
    this.metadata,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      amount: map['amount'].toDouble(),
      type: map['type'],
      status: map['status'],
      date: DateTime.parse(map['date']),
      reference: map['reference'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'status': status,
      'date': date.toIso8601String(),
      'reference': reference,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        type,
        status,
        date,
        reference,
        metadata,
      ];
}

class Loan extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final double amount;
  final double interestRate;
  final int duration;
  final double monthlyRepayment;
  final String status;
  final String purpose;
  final List<String> guarantorIds;
  final DateTime disbursedAt;
  final DateTime dueDate;
  final DateTime createdAt;
  final Map<String, dynamic> employmentDetails;
  final Map<String, dynamic> bankDetails;
  final List<Document> documents;
  final List<Transaction> transactions;

  const Loan({
    required this.id,
    required this.userId,
    required this.productId,
    required this.amount,
    required this.interestRate,
    required this.duration,
    required this.monthlyRepayment,
    required this.status,
    required this.purpose,
    required this.guarantorIds,
    required this.disbursedAt,
    required this.dueDate,
    required this.createdAt,
    required this.employmentDetails,
    required this.bankDetails,
    required this.documents,
    required this.transactions,
  });

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'],
      userId: map['userId'],
      productId: map['productId'],
      amount: map['amount'].toDouble(),
      interestRate: map['interestRate'].toDouble(),
      duration: map['duration'],
      monthlyRepayment: map['monthlyRepayment'].toDouble(),
      status: map['status'],
      purpose: map['purpose'],
      guarantorIds: List<String>.from(map['guarantorIds']),
      disbursedAt: DateTime.parse(map['disbursedAt']),
      dueDate: DateTime.parse(map['dueDate']),
      createdAt: DateTime.parse(map['createdAt']),
      employmentDetails: Map<String, dynamic>.from(map['employmentDetails']),
      bankDetails: Map<String, dynamic>.from(map['bankDetails']),
      documents: (map['documents'] as List)
          .map((item) => Document.fromMap(item))
          .toList(),
      transactions: (map['transactions'] as List)
          .map((item) => Transaction.fromMap(item))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'amount': amount,
      'interestRate': interestRate,
      'duration': duration,
      'monthlyRepayment': monthlyRepayment,
      'status': status,
      'purpose': purpose,
      'guarantorIds': guarantorIds,
      'disbursedAt': disbursedAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'employmentDetails': employmentDetails,
      'bankDetails': bankDetails,
      'documents': documents.map((x) => x.toMap()).toList(),
      'transactions': transactions.map((x) => x.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        productId,
        amount,
        interestRate,
        duration,
        monthlyRepayment,
        status,
        purpose,
        guarantorIds,
        disbursedAt,
        dueDate,
        createdAt,
        employmentDetails,
        bankDetails,
        documents,
        transactions,
      ];
}

class LoanProduct extends Equatable {
  final String id;
  final String name;
  final String description;
  final double minAmount;
  final double maxAmount;
  final List<int> durations;
  final double baseInterestRate;
  final double processingFee;
  final bool requiresGuarantor;
  final int minGuarantors;
  final List<String> requiredDocuments;
  final bool isActive;
  final Map<String, dynamic>? terms;

  const LoanProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.minAmount,
    required this.maxAmount,
    required this.durations,
    required this.baseInterestRate,
    required this.processingFee,
    required this.requiresGuarantor,
    required this.minGuarantors,
    required this.requiredDocuments,
    required this.isActive,
    this.terms,
  });

  factory LoanProduct.fromMap(Map<String, dynamic> map) {
    return LoanProduct(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      minAmount: map['minAmount'].toDouble(),
      maxAmount: map['maxAmount'].toDouble(),
      durations: List<int>.from(map['durations']),
      baseInterestRate: map['baseInterestRate'].toDouble(),
      processingFee: map['processingFee'].toDouble(),
      requiresGuarantor: map['requiresGuarantor'],
      minGuarantors: map['minGuarantors'],
      requiredDocuments: List<String>.from(map['requiredDocuments']),
      isActive: map['isActive'],
      terms: map['terms'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'durations': durations,
      'baseInterestRate': baseInterestRate,
      'processingFee': processingFee,
      'requiresGuarantor': requiresGuarantor,
      'minGuarantors': minGuarantors,
      'requiredDocuments': requiredDocuments,
      'isActive': isActive,
      'terms': terms,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        minAmount,
        maxAmount,
        durations,
        baseInterestRate,
        processingFee,
        requiresGuarantor,
        minGuarantors,
        requiredDocuments,
        isActive,
        terms,
      ];
}

class LoanApplication extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final double amount;
  final int duration;
  final String purpose;
  final String status;
  final List<String> guarantorIds;
  final Map<String, dynamic> employmentDetails;
  final Map<String, dynamic> bankDetails;
  final List<String> documentIds;
  final DateTime createdAt;
  final String? rejectionReason;

  const LoanApplication({
    required this.id,
    required this.userId,
    required this.productId,
    required this.amount,
    required this.duration,
    required this.purpose,
    required this.status,
    required this.guarantorIds,
    required this.employmentDetails,
    required this.bankDetails,
    required this.documentIds,
    required this.createdAt,
    this.rejectionReason,
  });

  factory LoanApplication.fromMap(Map<String, dynamic> map) {
    return LoanApplication(
      id: map['id'],
      userId: map['userId'],
      productId: map['productId'],
      amount: map['amount'].toDouble(),
      duration: map['duration'],
      purpose: map['purpose'],
      status: map['status'],
      guarantorIds: List<String>.from(map['guarantorIds']),
      employmentDetails: Map<String, dynamic>.from(map['employmentDetails']),
      bankDetails: Map<String, dynamic>.from(map['bankDetails']),
      documentIds: List<String>.from(map['documentIds']),
      createdAt: DateTime.parse(map['createdAt']),
      rejectionReason: map['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'amount': amount,
      'duration': duration,
      'purpose': purpose,
      'status': status,
      'guarantorIds': guarantorIds,
      'employmentDetails': employmentDetails,
      'bankDetails': bankDetails,
      'documentIds': documentIds,
      'createdAt': createdAt.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        productId,
        amount,
        duration,
        purpose,
        status,
        guarantorIds,
        employmentDetails,
        bankDetails,
        documentIds,
        createdAt,
        rejectionReason,
      ];
}

class LoanRepayment extends Equatable {
  final String id;
  final String loanId;
  final double amount;
  final DateTime dueDate;
  final String status;
  final DateTime? paidAt;
  final String? transactionId;

  const LoanRepayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paidAt,
    this.transactionId,
  });

  factory LoanRepayment.fromMap(Map<String, dynamic> map) {
    return LoanRepayment(
      id: map['id'],
      loanId: map['loanId'],
      amount: map['amount'].toDouble(),
      dueDate: DateTime.parse(map['dueDate']),
      status: map['status'],
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt']) : null,
      transactionId: map['transactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loanId': loanId,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'paidAt': paidAt?.toIso8601String(),
      'transactionId': transactionId,
    };
  }

  @override
  List<Object?> get props => [
        id,
        loanId,
        amount,
        dueDate,
        status,
        paidAt,
        transactionId,
      ];
}

class LoanEligibility extends Equatable {
  final bool isEligible;
  final double? maxAmount;
  final List<String>? reasons;
  final Map<String, dynamic>? requirements;

  const LoanEligibility({
    required this.isEligible,
    this.maxAmount,
    this.reasons,
    this.requirements,
  });

  factory LoanEligibility.fromMap(Map<String, dynamic> map) {
    return LoanEligibility(
      isEligible: map['isEligible'],
      maxAmount: map['maxAmount']?.toDouble(),
      reasons: map['reasons'] != null ? List<String>.from(map['reasons']) : null,
      requirements: map['requirements'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEligible': isEligible,
      'maxAmount': maxAmount,
      'reasons': reasons,
      'requirements': requirements,
    };
  }

  @override
  List<Object?> get props => [isEligible, maxAmount, reasons, requirements];
}
