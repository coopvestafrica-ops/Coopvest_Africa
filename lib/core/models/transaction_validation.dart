import 'dart:convert';

class TransactionValidationResult {
  final bool isValid;
  final List<String> errors;
  final Map<String, dynamic>? sanitizedData;

  TransactionValidationResult({
    required this.isValid,
    this.errors = const [],
    this.sanitizedData,
  });
}

class TransactionValidator {
  static TransactionValidationResult validateTransaction({
    required String userId,
    required String type,
    required double amount,
    required String currency,
    required String status,
    String? reference,
    String? description,
    Map<String, dynamic>? metadata,
    String? goalId,
  }) {
    final errors = <String>[];
    final sanitizedData = <String, dynamic>{};

    // Validate userId
    if (userId.isEmpty) {
      errors.add('User ID is required');
    } else {
      sanitizedData['userId'] = userId;
    }

    // Validate type
    final validTypes = ['credit', 'debit', 'transfer'];
    if (!validTypes.contains(type.toLowerCase())) {
      errors.add('Invalid transaction type. Must be one of: ${validTypes.join(", ")}');
    } else {
      sanitizedData['type'] = type.toLowerCase();
    }

    // Validate amount
    if (amount <= 0) {
      errors.add('Amount must be greater than 0');
    } else {
      sanitizedData['amount'] = amount;
    }

    // Validate currency
    final validCurrencies = ['NGN', 'USD', 'EUR', 'GBP'];
    if (!validCurrencies.contains(currency.toUpperCase())) {
      errors.add('Invalid currency. Must be one of: ${validCurrencies.join(", ")}');
    } else {
      sanitizedData['currency'] = currency.toUpperCase();
    }

    // Validate status
    final validStatuses = ['pending', 'completed', 'failed', 'cancelled'];
    if (!validStatuses.contains(status.toLowerCase())) {
      errors.add('Invalid status. Must be one of: ${validStatuses.join(", ")}');
    } else {
      sanitizedData['status'] = status.toLowerCase();
    }

    // Validate reference if provided
    if (reference != null) {
      if (reference.isEmpty) {
        errors.add('Reference cannot be empty if provided');
      } else {
        sanitizedData['reference'] = reference;
      }
    }

    // Validate description if provided
    if (description != null) {
      if (description.isEmpty) {
        errors.add('Description cannot be empty if provided');
      } else if (description.length > 500) {
        errors.add('Description must not exceed 500 characters');
      } else {
        sanitizedData['description'] = description;
      }
    }

    // Validate metadata if provided
    if (metadata != null) {
      try {
        // Ensure metadata is serializable
        final encoded = jsonEncode(metadata);
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;
        sanitizedData['metadata'] = decoded;
      } catch (e) {
        errors.add('Invalid metadata format. Must be JSON serializable');
      }
    }

    // Validate goalId if provided
    if (goalId != null) {
      if (goalId.isEmpty) {
        errors.add('Goal ID cannot be empty if provided');
      } else {
        sanitizedData['goalId'] = goalId;
      }
    }

    return TransactionValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      sanitizedData: errors.isEmpty ? sanitizedData : null,
    );
  }
}
