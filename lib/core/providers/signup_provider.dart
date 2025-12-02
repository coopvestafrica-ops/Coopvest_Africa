import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../models/auth_result.dart';
import '../models/field_status.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Rule for validating referral codes
class _ReferralCodeRule extends ValidationRule<String> {
  const _ReferralCodeRule([super.fieldName]);

  @override
  Future<ValidationResult> validate(String? value) async {
    if (value == null || value.isEmpty) return ValidationResult.valid();
    
    final field = fieldName?.toLowerCase() ?? 'referral code';
    
    if (!RegExp(r'^[A-Z0-9]{6,8}$').hasMatch(value)) {
      return ValidationResult.invalid('Invalid $field format');
    }

    return ValidationResult.valid();
  }
}

class SignupProvider extends ChangeNotifier {
  final AuthService _authService;
  final BiometricService _biometricService;
  final DeviceInfoPlugin _deviceInfo;
  
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;
  Timer? _debounceTimer;
  Timer? _emailCheckTimer;
  Timer? _phoneCheckTimer;
  
  Map<String, dynamic>? _deviceData;
  bool _isDeviceTrusted = false;
  bool _biometricEnabled = false;

  // Field statuses
  final Map<String, FieldStatus<String>> _fields = {
    'firstName': const FieldStatus<String>(
      rules: [RequiredRule('First name')],
    ),
    'lastName': const FieldStatus<String>(
      rules: [RequiredRule('Last name')],
    ),
    'email': const FieldStatus<String>(
      rules: [RequiredRule('Email'), EmailRule()],
    ),
    'phone': const FieldStatus<String>(
      rules: [RequiredRule('Phone number'), PhoneRule()],
    ),
    'password': const FieldStatus<String>(
      rules: [RequiredRule('Password'), PasswordRule()],
    ),
    'confirmPassword': const FieldStatus<String>(
      rules: [RequiredRule('Confirm password')],
    ),
    'referralCode': const FieldStatus<String>(),
  };

  // Password strength indicators
  final Map<String, bool> _passwordStrength = <String, bool>{
    'length': false,
    'uppercase': false,
    'lowercase': false,
    'numbers': false,
    'special': false,
  };

  SignupProvider(this._authService, this._biometricService, this._deviceInfo) {
    _initializeDevice();
  }

  Future<void> _initializeDevice() async {
    try {
      await _biometricService.initialize();
      _biometricEnabled = _biometricService.isBiometricEnabled();
      
      _deviceData = await _deviceInfo.deviceInfo.then((info) => info.data);
      
      // Check if device has security features enabled
      _isDeviceTrusted = await _biometricService.hasSecureBiometrics();
      
      if (!_disposed) notifyListeners();
    } catch (e) {
      debugPrint('Device initialization error: $e');
    }
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, FieldStatus<String>> get fields => Map.unmodifiable(_fields);
  Map<String, bool> get passwordStrength => Map.unmodifiable(_passwordStrength);
  bool get isFormValid => _fields.values.every((field) => field.isValid);
  bool get isBiometricEnabled => _biometricEnabled;
  bool get isDeviceTrusted => _isDeviceTrusted;
  
  FieldStatus<String> getField(String fieldName) => 
      _fields[fieldName] ?? const FieldStatus<String>();
  
  String? getFieldError(String fieldName) => _fields[fieldName]?.error;

  void updateField(String fieldName, String? value) async {
    if (_disposed) return;

    // Cancel any existing timers
    if (fieldName == 'email') {
      _emailCheckTimer?.cancel();
      _emailCheckTimer = Timer(const Duration(milliseconds: 500), () async {
        if (_disposed) return;
        
        final emailField = _fields[fieldName]!.withValue(value);
        final validatedField = await emailField.validate();
        _fields[fieldName] = validatedField;
        
        notifyListeners();
        
        if (validatedField.isValid && value != null && value.isNotEmpty) {
          // The real-time email check was removed as the method does not exist on AuthService.
          // Final validation will occur on form submission.
        }
      });
      return;
    }

    // For all other fields, use the general debounce timer
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (_disposed) return;

      FieldStatus<String> updatedField;

      switch (fieldName) {
          case 'password':
          // Update password strength indicators
          _passwordStrength.update('length', (_) => (value?.length ?? 0) >= 8);
          _passwordStrength.update('uppercase', (_) => RegExp(r'[A-Z]').hasMatch(value ?? ''));
          _passwordStrength.update('lowercase', (_) => RegExp(r'[a-z]').hasMatch(value ?? ''));
          _passwordStrength.update('numbers', (_) => RegExp(r'[0-9]').hasMatch(value ?? ''));
          _passwordStrength.update('special', (_) => RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value ?? ''));
          
          updatedField = _fields[fieldName]!.withValue(value);
          final validatedField = await updatedField.validate();
          _fields[fieldName] = validatedField;

          // Also validate confirm password if it exists and has a value
          final confirmValue = _fields['confirmPassword']?.value;
          if (confirmValue != null && confirmValue.isNotEmpty) {
            final confirmField = _fields['confirmPassword']!;
            final matchRule = MatchRule<String>(
              otherValue: value ?? '',
              otherFieldName: 'Password',
              fieldName: 'Confirm password',
            );
            _fields['confirmPassword'] = await confirmField.copyWith(
              rules: [
                const RequiredRule('Confirm password'),
                matchRule,
              ],
            ).validate();
          }
          break;          case 'confirmPassword':
          final field = _fields[fieldName]!;
          final passwordValue = _fields['password']?.value ?? '';
          final matchRule = MatchRule<String>(
            otherValue: passwordValue,
            otherFieldName: 'Password',
            fieldName: 'Confirm password',
          );
          updatedField = await field.copyWith(
            value: value,
            rules: [
                              RequiredRule('Confirm password'),
              matchRule,
            ],
          ).validate();
          _fields[fieldName] = updatedField;
          break;

        case 'referralCode':
          updatedField = _fields[fieldName]!.withValue(value);
          if (value?.isNotEmpty == true) {
            final referralRule = _ReferralCodeRule('Referral code');
            updatedField = await updatedField.copyWith(rules: [referralRule]).validate();
          } else {
            updatedField = await updatedField.validate();
          }
          _fields[fieldName] = updatedField;
          break;        default:
          updatedField = _fields[fieldName]!.withValue(value);
          _fields[fieldName] = await updatedField.validate();
      }

      notifyListeners();
    });
  }

  // Cancel all debounce timers
  void _cancelTimers() {
    _debounceTimer?.cancel();
    _emailCheckTimer?.cancel();
    _phoneCheckTimer?.cancel();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTimers();
    super.dispose();
  }

  Future<AuthResult> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    if (_disposed) {
      return AuthResult.failure(
        error: 'Provider has been disposed',
        errorType: AuthErrorType.unknown,
      );
    }

    // Validate all fields first
    _fields['firstName'] = _fields['firstName']!.withValue(firstName);
    _fields['lastName'] = _fields['lastName']!.withValue(lastName);
    _fields['email'] = _fields['email']!.withValue(email);
    _fields['phone'] = _fields['phone']!.withValue(phone);
    _fields['password'] = _fields['password']!.withValue(password);
    if (referralCode != null) {
      _fields['referralCode'] = _fields['referralCode']!.withValue(referralCode);
    }

    final validations = await Future.wait([
      _fields['firstName']!.validate(),
      _fields['lastName']!.validate(),
      _fields['email']!.validate(),
      _fields['phone']!.validate(),
      _fields['password']!.validate(),
      if (referralCode != null) _fields['referralCode']!.validate(),
    ]);

    // Update fields with validation results
    _fields['firstName'] = validations[0];
    _fields['lastName'] = validations[1];
    _fields['email'] = validations[2];
    _fields['phone'] = validations[3];
    _fields['password'] = validations[4];
    if (referralCode != null) {
      _fields['referralCode'] = validations[5];
    }

    notifyListeners();

    if (!isFormValid) {
      final fieldErrors = <String, String>{};
      for (final entry in _fields.entries) {
        if (entry.value.error != null) {
          fieldErrors[entry.key] = entry.value.error!;
        }
      }

      return AuthResult.failure(
        error: 'Please fix the errors in the form',
        errorType: AuthErrorType.unauthorized,
        data: {'fieldErrors': fieldErrors},
      );
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check biometric auth if enabled and required
      if (_biometricEnabled) {
        final biometricResult = await _biometricService.authenticate();
        if (!biometricResult.success) {
          return AuthResult.biometricRequired(biometricResult.error);
        }
      }

      // Check device trust status
      if (!_isDeviceTrusted) {
        return AuthResult.failure(
          error: 'Device verification required',
          errorType: AuthErrorType.unauthorized,
          data: {'deviceData': _deviceData},
        );
      }

      // Attempt registration
      final user = await _authService.register(
        email: email,
        username: email, // Using email as username
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phone,
      );

      _isLoading = false;
      if (!_disposed) notifyListeners();
      
      // Convert User response to AuthResult
      return AuthResult.success(
        token: user.meta['token'] as String? ?? '', // Get token from meta
        data: {
          'userId': user.id,
          'email': user.email,
          'firstName': user.firstName,
          'lastName': user.lastName,
          'phone': user.phoneNumber,
          'role': user.role.toString(),
          'isEmailVerified': user.isEmailVerified,
          'isPhoneVerified': user.isPhoneVerified,
          'deviceData': _deviceData,
          'biometricEnabled': _biometricEnabled,
          if (referralCode != null) 'referralCode': referralCode,
        },
      );

    } catch (e) {
      _isLoading = false;
      final errorLower = e.toString().toLowerCase();
      AuthResult failureResult;

      if (errorLower.contains('email') && errorLower.contains('use')) {
        failureResult = AuthResult.failure(
          error: 'This email is already registered',
          errorType: AuthErrorType.unauthorized,
          data: const {'fieldErrors': {'email': 'Email is already in use'}},
        );
      } else if (errorLower.contains('password') && errorLower.contains('weak')) {
        failureResult = AuthResult.failure(
          error: 'Please choose a stronger password',
          errorType: AuthErrorType.unauthorized,
          data: const {'fieldErrors': {'password': 'Password is too weak'}},
        );
      } else if (errorLower.contains('network') || errorLower.contains('connection')) {
        failureResult = AuthResult.networkError();
      } else {
        failureResult = AuthResult.serverError();
      }

      _error = failureResult.error;
      if (!_disposed) notifyListeners();
      return failureResult;
    }
  }

  void clearError() {
    if (_disposed) return;
    _error = null;
    notifyListeners();
  }

  void clearField(String fieldName) {
    if (_disposed) return;
    _fields[fieldName] = const FieldStatus();
    notifyListeners();
  }

  void clearForm() {
    if (_disposed) return;
    for (final key in _fields.keys) {
      _fields[key] = const FieldStatus<String>();
    }
    _error = null;
    _isLoading = false;
    _passwordStrength.updateAll((key, value) => false);
    notifyListeners();
  }

  Future<void> enableBiometrics() async {
    if (_disposed) return;

    try {
      if (await _biometricService.checkBiometricAvailability()) {
        final authResult = await _biometricService.authenticate(
          localizedReason: 'Please authenticate to enable biometric login',
        );
        if (authResult.success) {
          await _biometricService.setBiometricEnabled(true);
          _biometricEnabled = true;
          if (!_disposed) notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Biometric enablement error: $e');
    }
  }

  Future<void> refreshDeviceStatus() async {
    if (_disposed) return;

    try {
      _deviceData = await _deviceInfo.deviceInfo.then((info) => info.data);
      _isDeviceTrusted = await _biometricService.hasSecureBiometrics();
      _biometricEnabled = _biometricService.isBiometricEnabled();
      if (!_disposed) notifyListeners();
    } catch (e) {
      debugPrint('Device status refresh error: $e');
    }
  }
}
