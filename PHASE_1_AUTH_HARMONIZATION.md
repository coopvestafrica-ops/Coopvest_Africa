# Phase 1: Authentication Harmonization - Detailed Implementation Guide

## Overview

This guide provides step-by-step instructions for implementing unified authentication across Flutter, React, and Laravel.

---

## Backend Implementation (Laravel)

### Step 1: Create Authentication Controller

```php
// app/Http/Controllers/Api/AuthController.php

namespace App\Http\Controllers\Api;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

class AuthController extends Controller
{
    protected $jwtSecret;
    protected $jwtAlgorithm = 'HS256';

    public function __construct()
    {
        $this->jwtSecret = config('app.jwt_secret');
    }

    /**
     * Register a new user
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|unique:users',
            'password' => 'required|min:8|confirmed',
            'first_name' => 'required|string',
            'last_name' => 'required|string',
            'phone_number' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse(
                'Validation failed',
                $validator->errors(),
                422
            );
        }

        try {
            $user = User::create([
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'first_name' => $request->first_name,
                'last_name' => $request->last_name,
                'phone_number' => $request->phone_number,
                'is_verified' => false,
            ]);

            $tokens = $this->generateTokens($user);

            return $this->successResponse(
                'User registered successfully',
                [
                    'user' => $user,
                    'access_token' => $tokens['access_token'],
                    'refresh_token' => $tokens['refresh_token'],
                    'expires_in' => 3600,
                ],
                201
            );
        } catch (\Exception $e) {
            return $this->errorResponse(
                'Registration failed',
                ['error' => $e->getMessage()],
                500
            );
        }
    }

    /**
     * Login user
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse(
                'Validation failed',
                $validator->errors(),
                422
            );
        }

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return $this->errorResponse(
                'Invalid credentials',
                ['code' => 'AUTH_001'],
                401
            );
        }

        if (!$user->is_active) {
            return $this->errorResponse(
                'Account is inactive',
                ['code' => 'AUTH_008'],
                403
            );
        }

        $tokens = $this->generateTokens($user);
        $user->update(['last_login' => now()]);

        return $this->successResponse(
            'Login successful',
            [
                'user' => $user,
                'access_token' => $tokens['access_token'],
                'refresh_token' => $tokens['refresh_token'],
                'expires_in' => 3600,
            ]
        );
    }

    /**
     * Refresh access token
     */
    public function refreshToken(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'refresh_token' => 'required',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse(
                'Validation failed',
                $validator->errors(),
                422
            );
        }

        try {
            $decoded = JWT::decode(
                $request->refresh_token,
                new Key($this->jwtSecret, $this->jwtAlgorithm)
            );

            $user = User::find($decoded->sub);

            if (!$user) {
                return $this->errorResponse(
                    'User not found',
                    ['code' => 'AUTH_002'],
                    404
                );
            }

            $tokens = $this->generateTokens($user);

            return $this->successResponse(
                'Token refreshed',
                [
                    'access_token' => $tokens['access_token'],
                    'refresh_token' => $tokens['refresh_token'],
                    'expires_in' => 3600,
                ]
            );
        } catch (\Exception $e) {
            return $this->errorResponse(
                'Invalid refresh token',
                ['code' => 'AUTH_006'],
                401
            );
        }
    }

    /**
     * Logout user
     */
    public function logout(Request $request)
    {
        return $this->successResponse('Logout successful');
    }

    /**
     * Get current user
     */
    public function me(Request $request)
    {
        return $this->successResponse(
            'User retrieved',
            ['user' => $request->user()]
        );
    }

    /**
     * Generate JWT tokens
     */
    protected function generateTokens(User $user)
    {
        $now = time();
        $accessTokenExpiry = $now + 3600;
        $refreshTokenExpiry = $now + (30 * 24 * 60 * 60);

        $accessPayload = [
            'sub' => $user->id,
            'email' => $user->email,
            'role' => $user->role,
            'iat' => $now,
            'exp' => $accessTokenExpiry,
            'iss' => 'coopvest-africa',
            'aud' => 'coopvest-africa-app',
        ];

        $refreshPayload = [
            'sub' => $user->id,
            'iat' => $now,
            'exp' => $refreshTokenExpiry,
            'iss' => 'coopvest-africa',
            'type' => 'refresh',
        ];

        return [
            'access_token' => JWT::encode($accessPayload, $this->jwtSecret, $this->jwtAlgorithm),
            'refresh_token' => JWT::encode($refreshPayload, $this->jwtSecret, $this->jwtAlgorithm),
        ];
    }

    /**
     * Success response
     */
    protected function successResponse($message, $data = null, $status = 200)
    {
        return response()->json([
            'success' => true,
            'status' => $status,
            'message' => $message,
            'data' => $data,
            'timestamp' => now()->toIso8601String(),
        ], $status);
    }

    /**
     * Error response
     */
    protected function errorResponse($message, $details = null, $status = 400)
    {
        return response()->json([
            'success' => false,
            'status' => $status,
            'error' => [
                'message' => $message,
                'details' => $details,
            ],
            'timestamp' => now()->toIso8601String(),
        ], $status);
    }
}
```

---

## Frontend Implementation (React)

### Step 1: Create Auth Service

```typescript
// src/services/auth.service.ts

import { ApiResponse, User, AuthTokens } from '@/types';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

export class AuthService {
  static async register(
    email: string,
    password: string,
    firstName: string,
    lastName: string,
    phoneNumber?: string
  ): Promise<{ user: User; tokens: AuthTokens }> {
    const response = await fetch(`${API_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        password,
        password_confirmation: password,
        first_name: firstName,
        last_name: lastName,
        phone_number: phoneNumber,
      }),
    });

    const result: ApiResponse<any> = await response.json();

    if (!result.success) {
      throw new Error(result.error?.message || 'Registration failed');
    }

    return {
      user: result.data.user,
      tokens: {
        accessToken: result.data.access_token,
        refreshToken: result.data.refresh_token,
        expiresIn: result.data.expires_in,
      },
    };
  }

  static async login(
    email: string,
    password: string
  ): Promise<{ user: User; tokens: AuthTokens }> {
    const response = await fetch(`${API_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });

    const result: ApiResponse<any> = await response.json();

    if (!result.success) {
      throw new Error(result.error?.message || 'Login failed');
    }

    return {
      user: result.data.user,
      tokens: {
        accessToken: result.data.access_token,
        refreshToken: result.data.refresh_token,
        expiresIn: result.data.expires_in,
      },
    };
  }

  static async refreshToken(refreshToken: string): Promise<AuthTokens> {
    const response = await fetch(`${API_URL}/auth/refresh-token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refresh_token: refreshToken }),
    });

    const result: ApiResponse<any> = await response.json();

    if (!result.success) {
      throw new Error('Token refresh failed');
    }

    return {
      accessToken: result.data.access_token,
      refreshToken: result.data.refresh_token,
      expiresIn: result.data.expires_in,
    };
  }

  static async logout(accessToken: string): Promise<void> {
    await fetch(`${API_URL}/auth/logout`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`,
      },
    });
  }

  static async getCurrentUser(accessToken: string): Promise<User> {
    const response = await fetch(`${API_URL}/auth/me`, {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    });

    const result: ApiResponse<{ user: User }> = await response.json();

    if (!result.success) {
      throw new Error('Failed to fetch user');
    }

    return result.data.user;
  }
}
```

---

## Mobile Implementation (Flutter)

### Step 1: Create Auth Service

```dart
// lib/services/auth/auth_service.dart

import 'package:dio/dio.dart';
import '../../models/user_model.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';
import '../storage/token_manager.dart';

class AuthService {
  final Dio _dio;
  final TokenManager _tokenManager;
  final String baseUrl;

  AuthService({
    required this.baseUrl,
    required TokenManager tokenManager,
    Dio? dio,
  })  : _tokenManager = tokenManager,
        _dio = dio ?? Dio();

  /// Register new user
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      AppLogger.info('Registering user: $email');

      final response = await _dio.post(
        '$baseUrl/api/v1/auth/register',
        data: {
          'email': email,
          'password': password,
          'password_confirmation': password,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data['data']);
      
      await _tokenManager.setTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        expiry: authResponse.tokenExpiry,
        userId: authResponse.user.id,
      );

      AppLogger.info('User registered successfully');
      return authResponse;
    } catch (e) {
      AppLogger.error('Registration failed', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Login user
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Logging in user: $email');

      final response = await _dio.post(
        '$baseUrl/api/v1/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data['data']);
      
      await _tokenManager.setTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        expiry: authResponse.tokenExpiry,
        userId: authResponse.user.id,
      );

      AppLogger.info('User logged in successfully');
      return authResponse;
    } catch (e) {
      AppLogger.error('Login failed', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      AppLogger.info('Logging out user');

      final accessToken = await _tokenManager.getAccessToken();
      if (accessToken != null) {
        await _dio.post(
          '$baseUrl/api/v1/auth/logout',
          options: Options(
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          ),
        );
      }

      await _tokenManager.clearTokens();
      AppLogger.info('User logged out successfully');
    } catch (e) {
      AppLogger.error('Logout failed', e);
      await _tokenManager.clearTokens();
    }
  }
}
```

---

## Deployment Checklist

- [ ] Backend API endpoints tested
- [ ] JWT token generation verified
- [ ] Token refresh mechanism working
- [ ] Frontend auth context implemented
- [ ] Protected routes working
- [ ] Mobile auth service integrated
- [ ] Token storage secure
- [ ] Error handling consistent
- [ ] Tests passing (80%+ coverage)
- [ ] Documentation updated

---

## Next Steps

1. Implement backend authentication
2. Set up frontend auth context
3. Integrate mobile auth service
4. Test authentication flow
5. Deploy to staging
6. Proceed to Phase 2: API Standardization
