# Flutter App Integration - Firebase Auth & API Client

Complete Flutter implementation for Firebase authentication, secure token storage, API client with token injection, user sync to backend, protected routes, and comprehensive error handling.

## Features

### 1. Firebase Authentication Service
- ✅ Sign up with email and password
- ✅ Sign in with email and password
- ✅ Sign out
- ✅ Password reset
- ✅ Email verification
- ✅ User profile management
- ✅ ID token generation

### 2. Secure Token Storage
- ✅ Flutter Secure Storage integration
- ✅ Token persistence
- ✅ Token expiration tracking
- ✅ Automatic token refresh
- ✅ User ID storage
- ✅ Secure token clearing

### 3. API Client
- ✅ Automatic token injection in headers
- ✅ Request/response interceptors
- ✅ Error handling and retry logic
- ✅ Support for GET, POST, PUT, PATCH, DELETE
- ✅ File upload/download support
- ✅ Timeout configuration
- ✅ Logging and debugging

### 4. User Sync & Backend Integration
- ✅ User profile synchronization
- ✅ User data persistence (local caching)
- ✅ Profile updates
- ✅ Last login tracking
- ✅ Email verification status
- ✅ User info retrieval

### 5. Protected Routes & Navigation
- ✅ Route guards for authentication
- ✅ Automatic redirects based on auth state
- ✅ Splash screen for auth checking
- ✅ Protected screen wrapper
- ✅ GoRouter integration
- ✅ Navigation state management

### 6. Error Handling & User Feedback
- ✅ Custom exception hierarchy
- ✅ Firebase error mapping
- ✅ HTTP error handling
- ✅ Network error detection
- ✅ User feedback utilities (snackbars, dialogs)
- ✅ Comprehensive logging
- ✅ Error tracking

## Project Structure

```
lib/
├── core/
│   ├── exceptions/
│   │   └── app_exceptions.dart          # Custom exception classes
│   └── utils/
│       ├── logger.dart                  # Logging utility
│       ├── error_handler.dart           # Error handling and conversion
│       └── user_feedback.dart           # User feedback utilities
├── models/
│   ├── user_model.dart                  # User data models
│   └── user_model.g.dart                # Generated JSON serialization
├── services/
│   ├── auth/
│   │   ├── firebase_auth_service.dart   # Firebase authentication
│   │   └── auth_service.dart            # Main auth orchestration
│   ├── api/
│   │   └── api_client.dart              # HTTP client with interceptors
│   ├── storage/
│   │   ├── secure_token_storage.dart    # Secure token storage
│   │   └── token_manager.dart           # Token lifecycle management
│   └── user/
│       └── user_service.dart            # User profile management
├── navigation/
│   ├── route_guard.dart                 # Route protection logic
│   └── app_router.dart                  # GoRouter configuration
└── main.dart                            # App entry point
```

## Installation

### 1. Add Dependencies

```bash
flutter pub add firebase_core firebase_auth
flutter pub add dio http
flutter pub add provider riverpod
flutter pub add flutter_secure_storage shared_preferences
flutter pub add go_router
flutter pub add uuid intl logger json_annotation
flutter pub add flutter_spinkit
flutter pub add --dev build_runner json_serializable
```

### 2. Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Add your Flutter app to the project
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Place files in appropriate directories:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

### 3. Configure Backend URL

Update the API base URL in `main.dart`:

```dart
final apiClient = ApiClient(
  baseUrl: 'https://your-backend-api.com',
  tokenManager: tokenManager,
);
```

## Usage

### Initialize Services

```dart
// Services are initialized in main.dart
// All services are provided via Provider
```

### Sign Up

```dart
final authService = Provider.of<AuthService>(context, listen: false);

try {
  final user = await authService.signUp(
    email: 'user@example.com',
    password: 'password123',
    firstName: 'John',
    lastName: 'Doe',
    phoneNumber: '+1234567890',
  );
  print('User created: ${user.email}');
} catch (e) {
  print('Sign up failed: $e');
}
```

### Sign In

```dart
final authService = Provider.of<AuthService>(context, listen: false);

try {
  final user = await authService.signIn(
    email: 'user@example.com',
    password: 'password123',
  );
  print('Signed in: ${user.email}');
} catch (e) {
  print('Sign in failed: $e');
}
```

### Update Profile

```dart
final authService = Provider.of<AuthService>(context, listen: false);

try {
  final updatedUser = await authService.updateProfile(
    firstName: 'Jane',
    lastName: 'Smith',
    phoneNumber: '+9876543210',
    bio: 'Updated bio',
  );
  print('Profile updated: ${updatedUser.fullName}');
} catch (e) {
  print('Update failed: $e');
}
```

### Make API Requests

```dart
final apiClient = ApiClient(
  baseUrl: 'https://api.example.com',
  tokenManager: tokenManager,
);

// GET request
final data = await apiClient.get<Map<String, dynamic>>(
  endpoint: '/api/users/profile',
);

// POST request
final response = await apiClient.post<Map<String, dynamic>>(
  endpoint: '/api/users',
  data: {'name': 'John Doe'},
);

// File upload
final uploadResponse = await apiClient.uploadFile<Map<String, dynamic>>(
  endpoint: '/api/upload',
  filePath: '/path/to/file',
  fileName: 'profile.jpg',
);
```

### Show User Feedback

```dart
// Success message
UserFeedback.showSuccess(
  context,
  message: 'Profile updated successfully',
);

// Error message
UserFeedback.showError(
  context,
  message: 'Failed to update profile',
);

// Confirmation dialog
final confirmed = await UserFeedback.showConfirmationDialog(
  context,
  title: 'Confirm Action',
  message: 'Are you sure?',
);
```

### Protected Routes

Routes are automatically protected based on authentication state. The app will:
1. Show splash screen while checking auth status
2. Redirect to login if not authenticated
3. Redirect to home if authenticated
4. Automatically refresh tokens when needed

## Error Handling

The app includes comprehensive error handling:

```dart
try {
  await authService.signIn(email: email, password: password);
} on InvalidCredentialsException catch (e) {
  print('Invalid credentials: ${e.message}');
} on NetworkException catch (e) {
  print('Network error: ${e.message}');
} on ServerException catch (e) {
  print('Server error: ${e.message}');
} on AppException catch (e) {
  print('App error: ${e.message}');
}
```

## Token Management

Tokens are automatically managed:
- Stored securely using Flutter Secure Storage
- Automatically injected into API requests
- Refreshed when approaching expiration
- Cleared on sign out

## Logging

Enable detailed logging for debugging:

```dart
AppLogger.debug('Debug message');
AppLogger.info('Info message');
AppLogger.warning('Warning message');
AppLogger.error('Error message', exception, stackTrace);
```

## Configuration

### Token Refresh Threshold

Modify token refresh timing in `token_manager.dart`:

```dart
static const Duration _refreshThreshold = Duration(minutes: 5);
```

### API Timeouts

Configure timeouts in `api_client.dart`:

```dart
static const int _connectTimeout = 30000; // 30 seconds
static const int _receiveTimeout = 30000; // 30 seconds
static const int _sendTimeout = 30000; // 30 seconds
```

## Best Practices

1. **Always use AuthService** for authentication operations
2. **Handle exceptions** appropriately in UI
3. **Show user feedback** for all operations
4. **Check auth status** before accessing protected resources
5. **Log important events** for debugging
6. **Keep tokens secure** - never log or expose them
7. **Implement proper error recovery** flows

## Testing

### Unit Tests

```dart
test('Token manager should refresh token when needed', () async {
  final tokenManager = TokenManager();
  // Add test implementation
});
```

### Integration Tests

```dart
testWidgets('Sign in flow', (WidgetTester tester) async {
  // Add integration test
});
```

## Troubleshooting

### Firebase Initialization Error
- Ensure `google-services.json` and `GoogleService-Info.plist` are properly configured
- Check Firebase project settings

### Token Not Being Injected
- Verify `TokenManager` is initialized before `ApiClient`
- Check token is not expired
- Ensure `Authorization` header is not being overridden

### Protected Routes Not Working
- Verify `AuthService` is provided via Provider
- Check `GoRouter` configuration
- Ensure auth state changes trigger redirects

## Contributing

1. Follow Dart style guide
2. Add tests for new features
3. Update documentation
4. Use meaningful commit messages

## License

This project is part of Coopvest Africa platform.

## Support

For issues and questions, please contact the development team.
