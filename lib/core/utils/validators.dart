class Validators {
  static String? validateAmount(String? value, {
    double? minAmount,
    double? maxAmount,
    String? currencySymbol = '₦',
  }) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }

    // Remove currency symbol and commas
    final cleanValue = value.replaceAll(currencySymbol ?? '', '')
        .replaceAll(',', '')
        .trim();

    try {
      final amount = double.parse(cleanValue);
      if (amount <= 0) {
        return 'Amount must be greater than zero';
      }
      if (minAmount != null && amount < minAmount) {
        return 'Amount cannot be less than $currencySymbol${minAmount.toStringAsFixed(2)}';
      }
      if (maxAmount != null && amount > maxAmount) {
        return 'Amount cannot exceed $currencySymbol${maxAmount.toStringAsFixed(2)}';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid amount';
    }
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove any spaces, dashes, or parentheses
    final cleanNumber = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it's a valid Nigerian phone number
    if (!RegExp(r'^\+?234[789][01]\d{8}$').hasMatch(cleanNumber) &&
        !RegExp(r'^0[789][01]\d{8}$').hasMatch(cleanNumber)) {
      return 'Please enter a valid Nigerian phone number';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }
}
