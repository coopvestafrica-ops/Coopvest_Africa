import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// A class that represents monetary values in the application.
/// This ensures type safety and proper handling of decimal values.
class Money extends Equatable {
  /// The amount in the smallest currency unit (kobo)
  final int amountInKobo;

  /// Creates a new Money instance from an amount in kobo
  const Money.fromKobo(this.amountInKobo);

  /// Creates a new Money instance from an amount in naira
  factory Money.fromNaira(double amount) {
    return Money.fromKobo((amount * 100).round());
  }

  /// The amount in naira
  double get inNaira => amountInKobo / 100.0;

  /// Returns true if this amount is greater than zero
  bool get isPositive => amountInKobo > 0;

  /// Returns true if this amount is less than zero
  bool get isNegative => amountInKobo < 0;

  /// Returns true if this amount is zero
  bool get isZero => amountInKobo == 0;

  /// Returns a formatted string representation of the amount
  String toFormattedString({bool withSymbol = true}) {
    final formatter = NumberFormat.currency(
      symbol: withSymbol ? '₦' : '',
      decimalDigits: 2,
    );
    return formatter.format(inNaira);
  }

  /// Returns a string with exactly the specified number of decimal places
  String toStringAsFixed(int decimals) {
    return inNaira.toStringAsFixed(decimals);
  }

  /// Adds two Money values
  Money operator +(Money other) {
    return Money.fromKobo(amountInKobo + other.amountInKobo);
  }

  /// Subtracts two Money values
  Money operator -(Money other) {
    return Money.fromKobo(amountInKobo - other.amountInKobo);
  }

  /// Multiplies a Money value by a number
  Money operator *(num factor) {
    return Money.fromKobo((amountInKobo * factor).round());
  }

  /// Divides a Money value by a number
  Money operator /(num divisor) {
    return Money.fromKobo((amountInKobo / divisor).round());
  }

  /// Returns true if this amount is greater than the other
  bool operator >(Money other) => amountInKobo > other.amountInKobo;

  /// Returns true if this amount is less than the other
  bool operator <(Money other) => amountInKobo < other.amountInKobo;

  /// Returns true if this amount is greater than or equal to the other
  bool operator >=(Money other) => amountInKobo >= other.amountInKobo;

  /// Returns true if this amount is less than or equal to the other
  bool operator <=(Money other) => amountInKobo <= other.amountInKobo;

  /// Returns true if this amount is greater than the amount in naira
  bool greaterThan(double amountInNaira) => 
    this > Money.fromNaira(amountInNaira);

  /// Returns true if this amount is less than the amount in naira
  bool lessThan(double amountInNaira) => 
    this < Money.fromNaira(amountInNaira);

  /// Creates a JSON representation of the money value
  Map<String, dynamic> toJson() => {
    'amountInKobo': amountInKobo,
  };

  /// Creates a Money instance from JSON
  factory Money.fromJson(Map<String, dynamic> json) {
    return Money.fromKobo(json['amountInKobo'] as int);
  }

  /// The zero money value
  static const zero = Money.fromKobo(0);

  @override
  List<Object> get props => [amountInKobo];

  @override
  String toString() => toFormattedString();
}
