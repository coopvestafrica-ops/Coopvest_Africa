import 'dart:async';
import 'package:coopvest/core/services/api_service.dart';
import 'package:coopvest/core/config/api_config.dart';
import 'package:coopvest/core/utils/result.dart';
import 'package:coopvest/core/exceptions/api_exception.dart';
import '../models/user.dart';

class AuthApiService {
  final ApiService _apiService;
  static const _maxRetries = 3;
  static const _defaultTimeout = Duration(seconds: 30);
  static final _retryableErrorCodes = {
    'NETWORK_ERROR',
    'SERVER_ERROR',
    'TIMEOUT_ERROR',
  };

  AuthApiService(this._apiService);

  /// Authenticates a user with their email and password
  /// Returns a Result containing User data on success
  Future<Result<T>> _executeWithRetry<T>(
    Future<T> Function() operation,
    String errorPrefix, {
    Duration timeout = _defaultTimeout,
    int maxRetries = _maxRetries,
  }) async {
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        final result = await operation().timeout(timeout);
        return Result.success(result);
      } catch (e) {
        if (e is ApiException) {
          // Don't retry if it's a client error (4xx) unless it's a token refresh error
          if (e.statusCode != null && 
              e.statusCode! >= 400 && 
              e.statusCode! < 500 && 
              e.errorCode != 'TOKEN_EXPIRED') {
            return Result.failure(
              '$errorPrefix: ${e.message}',
              errorCode: e.errorCode,
              data: e.errorData,
            );
          }
          
          // Retry if error is retryable and we haven't exceeded max attempts
          if (_retryableErrorCodes.contains(e.errorCode) && attempts < maxRetries) {
            await Future.delayed(Duration(milliseconds: (1 << attempts) * 1000));
            continue;
          }
        }
        
        return Result.failure(
          '$errorPrefix: ${e is ApiException ? e.message : e.toString()}',
          errorCode: e is ApiException ? e.errorCode : 'UNKNOWN_ERROR',
          data: e is ApiException ? e.errorData : null,
        );
      }
    }
  }

  Future<Result<User>> login({
    required String email,
    required String password,
    required Map<String, dynamic> deviceInfo,
  }) async {
    return _executeWithRetry(
      () async {
        final result = await _apiService.post<Map<String, dynamic>>(
          ApiConfig.login,
          {
            'email': email,
            'password': password,
            'deviceInfo': deviceInfo,
          },
          (json) => json,
        );
        
        if (!result.containsKey('user')) {
          throw ApiException(
            'Invalid response format',
            errorData: {'code': 'INVALID_RESPONSE'},
          );
        }

        return User.fromMap(result['user'] as Map<String, dynamic>);
      },
      'Login failed',
    );
  }

  Future<Result<void>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? referralCode,
  }) async {
    return _executeWithRetry(
      () async {
        final result = await _apiService.post<Map<String, dynamic>>(
          ApiConfig.register,
          {
            'email': email,
            'password': password,
            'firstName': firstName,
            'lastName': lastName,
            'phoneNumber': phoneNumber,
            if (referralCode != null) 'referralCode': referralCode,
          },
          (json) => json,
        );
        
        if (!result.containsKey('success')) {
          throw ApiException(
            'Invalid response format',
            errorData: {'code': 'INVALID_RESPONSE'},
          );
        }
        return;
      },
      'Registration failed',
    );
  }

  Future<Result<void>> verifyEmail(String code) async {
    return _executeWithRetry(
      () async {
        final result = await _apiService.post<Map<String, dynamic>>(
          ApiConfig.verifyEmail,
          {'code': code},
          (json) => json,
        );
        
        if (!result.containsKey('success')) {
          throw ApiException(
            'Invalid response format',
            errorData: {'code': 'INVALID_RESPONSE'},
          );
        }
        return;
      },
      'Email verification failed',
    );
  }

  Future<Result<void>> verifyPhone(String code) async {
    return _executeWithRetry(
      () async {
        final result = await _apiService.post<Map<String, dynamic>>(
          ApiConfig.verifyPhone,
          {'code': code},
          (json) => json,
        );
        
        if (!result.containsKey('success')) {
          throw ApiException(
            'Invalid response format',
            errorData: {'code': 'INVALID_RESPONSE'},
          );
        }
        return;
      },
      'Phone verification failed',
    );
  }

  Future<Result<void>> resetPassword(String email) async {
    return _executeWithRetry(
      () async {
        final result = await _apiService.post<Map<String, dynamic>>(
          ApiConfig.resetPassword,
          {'email': email},
          (json) => json,
        );
        
        if (!result.containsKey('success')) {
          throw ApiException(
            'Invalid response format',
            errorData: {'code': 'INVALID_RESPONSE'},
          );
        }
        return;
      },
      'Password reset failed',
    );
  }

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return _executeWithRetry(
      () async {
        final result = await _apiService.post<Map<String, dynamic>>(
          ApiConfig.changePassword,
          {
            'currentPassword': currentPassword,
            'newPassword': newPassword,
          },
          (json) => json,
        );
        
        if (!result.containsKey('success')) {
          throw ApiException(
            'Invalid response format',
            errorData: {'code': 'INVALID_RESPONSE'},
          );
        }
        return;
      },
      'Password change failed',
    );
  }

  Future<Result<User>> getUserProfile() async {
    return _executeWithRetry(
      () async {
        final data = await _apiService.get<Map<String, dynamic>>(
          ApiConfig.userProfile,
          (json) => json,
        );
        
        if (!data.containsKey('user')) {
          throw ApiException(
            'Invalid response format',
            errorData: {'code': 'INVALID_RESPONSE'},
          );
        }
        
        return User.fromMap(data['user'] as Map<String, dynamic>);
      },
      'Failed to get user profile',
    );
  }

  Future<Result<User>> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    return _executeWithRetry(
      () async {
        final data = await _apiService.put<Map<String, dynamic>>(
          ApiConfig.updateProfile,
          {
            if (firstName != null) 'firstName': firstName,
            if (lastName != null) 'lastName': lastName,
            if (phoneNumber != null) 'phoneNumber': phoneNumber,
            if (avatarUrl != null) 'avatarUrl': avatarUrl,
          },
          (json) => json,
        );
        
        if (!data.containsKey('user')) {
          throw ApiException(
            'Invalid response format',
            errorData: {'code': 'INVALID_RESPONSE'},
          );
        }
        
        return User.fromMap(data['user'] as Map<String, dynamic>);
      },
      'Profile update failed',
    );
  }

  Future<Result<void>> logout() async {
    return _executeWithRetry(
      () async {
        final result = await _apiService.post<Map<String, dynamic>>(
          ApiConfig.logout,
          {},
          (json) => json,
        );
        
        if (!result.containsKey('success')) {
          throw ApiException(
            'Invalid response format',
            errorData: {'code': 'INVALID_RESPONSE'},
          );
        }
        return;
      },
      'Logout failed',
    );
  }
}
