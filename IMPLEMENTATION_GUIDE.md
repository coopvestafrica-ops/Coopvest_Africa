# Flutter App Integration - Implementation Guide

Complete step-by-step guide for integrating Firebase authentication, API client, and user management into your Flutter app.

## Table of Contents

1. [Setup & Configuration](#setup--configuration)
2. [Firebase Integration](#firebase-integration)
3. [Service Integration](#service-integration)
4. [UI Implementation](#ui-implementation)
5. [Testing](#testing)
6. [Deployment](#deployment)

## Setup & Configuration

### Step 1: Project Setup

```bash
# Create new Flutter project
flutter create coopvest_africa

# Navigate to project
cd coopvest_africa

# Add dependencies
flutter pub add firebase_core firebase_auth
flutter pub add dio http
flutter pub add provider
flutter pub add flutter_secure_storage shared_preferences
flutter pub add go_router
flutter pub add uuid intl logger json_annotation
flutter pub add flutter_spinkit

# Dev dependencies
flutter pub add --dev build_runner json_serializable
```

### Step 2: Directory Structure

Create the following directory structure:

```
lib/
├── core/
│   ├── exceptions/
│   ├── utils/
│   └── constants/
├── models/
├── services/
│   ├── auth/
│   ├── api/
│   ├── storage/
│   └── user/
├── screens/
│   ├── auth/
│   ├── home/
│   └── profile/
├── widgets/
├── navigation/
└── main.dart
```

### Step 3: Environment Configuration

Create `lib/core/constants/app_constants.dart`:

```dart
class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'https://api.coopvestafrica.com';
  static const String apiVersion = 'v1';
  
  // Firebase Configuration
  static const String firebaseProjectId = 'your-project-id';
  
  // Token Configuration
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  static const Duration tokenExpiry = Duration(hours: 1);
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
```

## Firebase Integration

### Step 1: Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or select existing
3. Add Flutter app:
   - iOS: Download `GoogleService-Info.plist`
   - Android: Download `google-services.json`

### Step 2: Android Configuration

1. Place `google-services.json` in `android/app/`
2. Update `android/build.gradle`:

```gradle
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
  }
}
```

3. Update `android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
  implementation 'com.google.firebase:firebase-auth'
}
```

### Step 3: iOS Configuration

1. Place `GoogleService-Info.plist` in `ios/Runner/`
2. Add to Xcode project
3. Update `ios/Podfile`:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
      ]
    end
  end
end
```

### Step 4: Enable Authentication Methods

In Firebase Console:
1. Go to Authentication
2. Enable Email/Password provider
3. Configure password policy
4. Set up email templates

## Service Integration

### Step 1: Initialize Services in main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    
    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    
    // Initialize TokenManager
    final tokenManager = TokenManager();
    await tokenManager.initialize();
    
    // Initialize FirebaseAuthService
    final firebaseAuth = FirebaseAuthService();
    
    // Initialize ApiClient
    final apiClient = ApiClient(
      baseUrl: AppConstants.apiBaseUrl,
      tokenManager: tokenManager,
    );
    
    // Initialize UserService
    final userService = UserService(
      apiClient: apiClient,
      prefs: prefs,
    );
    await userService.initialize();
    
    // Initialize AuthService
    final authService = AuthService(
      firebaseAuth: firebaseAuth,
      tokenManager: tokenManager,
      userService: userService,
    );
    await authService.initialize();
    
    runApp(MyApp(authService: authService));
  } catch (e) {
    AppLogger.error('Failed to initialize app', e);
    runApp(const ErrorApp());
  }
}
```

### Step 2: Provide Services

```dart
class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({required this.authService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
      ],
      child: MaterialApp.router(
        routerConfig: AppRouter(authService: authService).getRouter(),
      ),
    );
  }
}
```

## UI Implementation

### Step 1: Login Screen

```dart
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    setState(() => _isLoading = true);

    try {
      await authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      if (mounted) {
        UserFeedback.showSuccess(context, message: 'Login successful');
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        UserFeedback.showError(
          context,
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 2: Sign Up Screen

```dart
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    setState(() => _isLoading = true);

    try {
      await authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
      );
      
      if (mounted) {
        UserFeedback.showSuccess(context, message: 'Account created successfully');
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        UserFeedback.showError(context, message: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignUp,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Step 3: Profile Screen

```dart
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    setState(() => _isLoading = true);

    try {
      await authService.updateProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneController.text,
        bio: _bioController.text,
      );
      
      if (mounted) {
        UserFeedback.showSuccess(context, message: 'Profile updated');
      }
    } catch (e) {
      if (mounted) {
        UserFeedback.showError(context, message: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdate,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Testing

### Unit Tests

Create `test/services/auth_service_test.dart`:

```dart
void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockFirebaseAuthService mockFirebaseAuth;
    late MockTokenManager mockTokenManager;
    late MockUserService mockUserService;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuthService();
      mockTokenManager = MockTokenManager();
      mockUserService = MockUserService();
      
      authService = AuthService(
        firebaseAuth: mockFirebaseAuth,
        tokenManager: mockTokenManager,
        userService: mockUserService,
      );
    });

    test('Sign in should update token manager', () async {
      // Add test implementation
    });

    test('Sign out should clear tokens', () async {
      // Add test implementation
    });
  });
}
```

### Integration Tests

Create `integration_test/auth_flow_test.dart`:

```dart
void main() {
  group('Authentication Flow', () {
    testWidgets('Complete sign up and login flow', (WidgetTester tester) async {
      // Add integration test
    });
  });
}
```

## Deployment

### Android Release Build

```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

### iOS Release Build

```bash
# Build iOS app
flutter build ios --release

# Archive for App Store
flutter build ios --release --no-codesign
```

### Firebase Deployment

1. Set up Firebase Hosting (optional)
2. Configure Crashlytics for error tracking
3. Set up Analytics for user tracking

## Troubleshooting

### Common Issues

1. **Firebase Initialization Error**
   - Verify google-services.json and GoogleService-Info.plist
   - Check Firebase project settings

2. **Token Not Injected**
   - Ensure TokenManager is initialized before ApiClient
   - Check token is not expired

3. **Protected Routes Not Working**
   - Verify AuthService is provided
   - Check GoRouter configuration

## Next Steps

1. Implement additional authentication methods (Google, Apple)
2. Add biometric authentication
3. Implement push notifications
4. Add offline support
5. Implement analytics tracking

## Support

For issues and questions, contact the development team.
