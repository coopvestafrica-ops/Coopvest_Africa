import 'package:equatable/equatable.dart';

/// Represents the status of a form field including its value, validity,
/// and any associated error message or validation state.
class FieldStatus<T> extends Equatable {
  /// The current value of the field
  final T? value;
  
  /// Whether the field has been touched/modified by the user
  final bool isDirty;
  
  /// Whether the field is currently being validated
  final bool isValidating;
  
  /// Whether the field's current value is valid
  final bool isValid;
  
  /// Whether the field has been successfully validated at least once
  final bool isValidated;
  
  /// The error message if the field is invalid
  final String? error;
  
  /// Optional validation rules for the field
  final List<ValidationRule<T>>? rules;

  /// Creates a new field status instance
  const FieldStatus({
    this.value,
    this.isDirty = false,
    this.isValidating = false,
    this.isValid = true,
    this.isValidated = false,
    this.error,
    this.rules,
  });

  /// Creates an initial field status
  factory FieldStatus.initial([T? initialValue]) => FieldStatus(
    value: initialValue,
    isDirty: false,
    isValidating: false,
    isValid: true,
    isValidated: false,
  );

  /// Creates a field status for a required field
  factory FieldStatus.required([String? fieldName]) => FieldStatus(
    rules: [RequiredRule(fieldName)],
  );

  /// Creates a loading state for the field
  FieldStatus<T> validating() => copyWith(
    isValidating: true,
    isValid: true,
    error: null,
  );

  /// Updates the field with a new value
  FieldStatus<T> withValue(T? newValue) => copyWith(
    value: newValue,
    isDirty: true,
    isValidating: false,
  );

  /// Marks the field as valid
  FieldStatus<T> valid() => copyWith(
    isValid: true,
    isValidated: true,
    isValidating: false,
    error: null,
  );

  /// Marks the field as invalid with an error message
  FieldStatus<T> invalid(String errorMessage) => copyWith(
    isValid: false,
    isValidated: true,
    isValidating: false,
    error: errorMessage,
  );

  /// Resets the field to its initial state
  FieldStatus<T> reset() => copyWith(
    value: null,
    isDirty: false,
    isValidating: false,
    isValid: true,
    isValidated: false,
    error: null,
  );

  /// Creates a copy of this field status with some properties changed
  FieldStatus<T> copyWith({
    T? value,
    bool? isDirty,
    bool? isValidating,
    bool? isValid,
    bool? isValidated,
    String? error,
    List<ValidationRule<T>>? rules,
  }) {
    return FieldStatus<T>(
      value: value ?? this.value,
      isDirty: isDirty ?? this.isDirty,
      isValidating: isValidating ?? this.isValidating,
      isValid: isValid ?? this.isValid,
      isValidated: isValidated ?? this.isValidated,
      error: error ?? this.error,
      rules: rules ?? this.rules,
    );
  }

  /// Validates the field using its validation rules
  Future<FieldStatus<T>> validate() async {
    if (rules == null || rules!.isEmpty) {
      return valid();
    }

    for (final rule in rules!) {
      final validationResult = await rule.validate(value);
      if (!validationResult.isValid) {
        return invalid(validationResult.error!);
      }
    }

    return valid();
  }

  @override
  List<Object?> get props => [
    value,
    isDirty,
    isValidating,
    isValid,
    isValidated,
    error,
    rules,
  ];
  
  @override
  String toString() => 'FieldStatus(value: $value, isDirty: $isDirty, '
    'isValidating: $isValidating, isValid: $isValid, '
    'isValidated: $isValidated, error: $error)';
}

/// Represents the result of a field validation
class ValidationResult extends Equatable {
  final bool isValid;
  final String? error;

  const ValidationResult({
    required this.isValid,
    this.error,
  });

  factory ValidationResult.valid() => const ValidationResult(isValid: true);
  
  factory ValidationResult.invalid(String error) => ValidationResult(
    isValid: false,
    error: error,
  );

  @override
  List<Object?> get props => [isValid, error];
}

/// Base class for field validation rules
abstract class ValidationRule<T> extends Equatable {
  final String? fieldName;
  
  const ValidationRule([this.fieldName]);
  
  Future<ValidationResult> validate(T? value);
  
  @override
  List<Object?> get props => [fieldName];
}

/// Rule for required fields that cannot be null or empty
class RequiredRule<T> extends ValidationRule<T> {
  const RequiredRule([super.fieldName]);

  @override
  Future<ValidationResult> validate(T? value) async {
    final field = fieldName?.toLowerCase() ?? 'field';
    
    if (value == null) {
      return ValidationResult.invalid('$field is required');
    }

    if (value is String && value.trim().isEmpty) {
      return ValidationResult.invalid('$field is required');
    }

    if (value is List && value.isEmpty) {
      return ValidationResult.invalid('$field is required');
    }

    if (value is Map && value.isEmpty) {
      return ValidationResult.invalid('$field is required');
    }

    return ValidationResult.valid();
  }
}

/// Rule for validating minimum length of strings or lists
class MinLengthRule extends ValidationRule<dynamic> {
  final int minLength;

  const MinLengthRule(this.minLength, [super.fieldName]);

  @override
  Future<ValidationResult> validate(dynamic value) async {
    if (value == null) return ValidationResult.valid();
    
    final field = fieldName?.toLowerCase() ?? 'field';
    int length = 0;

    if (value is String) {
      length = value.length;
    } else if (value is List) {
      length = value.length;
    } else {
      return ValidationResult.valid();
    }

    if (length < minLength) {
      return ValidationResult.invalid(
        '$field must be at least $minLength characters long'
      );
    }

    return ValidationResult.valid();
  }

  @override
  List<Object?> get props => [...super.props, minLength];
}

/// Rule for validating maximum length of strings or lists
class MaxLengthRule extends ValidationRule<dynamic> {
  final int maxLength;

  const MaxLengthRule(this.maxLength, [super.fieldName]);

  @override
  Future<ValidationResult> validate(dynamic value) async {
    if (value == null) return ValidationResult.valid();
    
    final field = fieldName?.toLowerCase() ?? 'field';
    int length = 0;

    if (value is String) {
      length = value.length;
    } else if (value is List) {
      length = value.length;
    } else {
      return ValidationResult.valid();
    }

    if (length > maxLength) {
      return ValidationResult.invalid(
        '$field must not exceed $maxLength characters'
      );
    }

    return ValidationResult.valid();
  }

  @override
  List<Object?> get props => [...super.props, maxLength];
}

/// Rule for validating email addresses
class EmailRule extends ValidationRule<String> {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  );

  const EmailRule([super.fieldName]);

  @override
  Future<ValidationResult> validate(String? value) async {
    if (value == null || value.isEmpty) return ValidationResult.valid();
    
    final field = fieldName?.toLowerCase() ?? 'email';

    if (!_emailRegex.hasMatch(value)) {
      return ValidationResult.invalid('Please enter a valid $field address');
    }

    return ValidationResult.valid();
  }
}

/// Rule for validating phone numbers
class PhoneRule extends ValidationRule<String> {
  static final _phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');

  const PhoneRule([super.fieldName]);

  @override
  Future<ValidationResult> validate(String? value) async {
    if (value == null || value.isEmpty) return ValidationResult.valid();
    
    final field = fieldName?.toLowerCase() ?? 'phone number';

    if (!_phoneRegex.hasMatch(value)) {
      return ValidationResult.invalid('Please enter a valid $field');
    }

    return ValidationResult.valid();
  }
}

/// Rule for validating passwords
class PasswordRule extends ValidationRule<String> {
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireNumbers;
  final bool requireSpecialChars;
  final int minLength;

  const PasswordRule({
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireNumbers = true,
    this.requireSpecialChars = true,
    this.minLength = 8,
    String? fieldName,
  }) : super(fieldName);

  @override
  Future<ValidationResult> validate(String? value) async {
    if (value == null || value.isEmpty) return ValidationResult.valid();
    
    final field = fieldName?.toLowerCase() ?? 'password';
    final errors = <String>[];

    if (value.length < minLength) {
      errors.add('$field must be at least $minLength characters long');
    }

    if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
      errors.add('$field must contain at least one uppercase letter');
    }

    if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
      errors.add('$field must contain at least one lowercase letter');
    }

    if (requireNumbers && !value.contains(RegExp(r'[0-9]'))) {
      errors.add('$field must contain at least one number');
    }

    if (requireSpecialChars && 
        !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('$field must contain at least one special character');
    }

    if (errors.isNotEmpty) {
      return ValidationResult.invalid(errors.join('\n'));
    }

    return ValidationResult.valid();
  }

  @override
  List<Object?> get props => [
    ...super.props,
    requireUppercase,
    requireLowercase,
    requireNumbers,
    requireSpecialChars,
    minLength,
  ];
}

/// Rule for comparing two fields (e.g., password confirmation)
class MatchRule<T> extends ValidationRule<T> {
  final T otherValue;
  final String otherFieldName;

  const MatchRule({
    required this.otherValue,
    required this.otherFieldName,
    String? fieldName,
  }) : super(fieldName);

  @override
  Future<ValidationResult> validate(T? value) async {
    if (value == null) return ValidationResult.valid();
    
    final field = fieldName?.toLowerCase() ?? 'field';

    if (value != otherValue) {
      return ValidationResult.invalid(
        '$field must match $otherFieldName'
      );
    }

    return ValidationResult.valid();
  }

  @override
  List<Object?> get props => [...super.props, otherValue, otherFieldName];
}

/// Rule for validating numbers within a range
class NumberRangeRule extends ValidationRule<num> {
  final num? min;
  final num? max;

  const NumberRangeRule({
    this.min,
    this.max,
    String? fieldName,
  }) : super(fieldName);

  @override
  Future<ValidationResult> validate(num? value) async {
    if (min == null && max == null) {
      return ValidationResult.invalid(
        'NumberRangeRule must have either min or max specified'
      );
    }

    if (value == null) return ValidationResult.valid();
    
    final field = fieldName?.toLowerCase() ?? 'number';

    if (min != null && value < min!) {
      return ValidationResult.invalid(
        '$field must be greater than or equal to $min'
      );
    }

    if (max != null && value > max!) {
      return ValidationResult.invalid(
        '$field must be less than or equal to $max'
      );
    }

    return ValidationResult.valid();
  }

  @override
  List<Object?> get props => [...super.props, min, max];
}