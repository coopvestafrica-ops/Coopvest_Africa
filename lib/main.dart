import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/utils/logger.dart';
import 'navigation/app_router.dart';
import 'services/api/api_client.dart';
import 'services/auth/auth_service.dart';
import 'services/auth/firebase_auth_service.dart';
import 'services/storage/token_manager.dart';
import 'services/user/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    AppLogger.info('Firebase initialized');

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    AppLogger.info('SharedPreferences initialized');

    // Initialize services
    final tokenManager = TokenManager();
    await tokenManager.initialize();
    AppLogger.info('TokenManager initialized');

    final firebaseAuth = FirebaseAuthService();
    AppLogger.info('FirebaseAuthService initialized');

    final apiClient = ApiClient(
      baseUrl: 'https://api.coopvestafrica.com', // Replace with your backend URL
      tokenManager: tokenManager,
    );
    AppLogger.info('ApiClient initialized');

    final userService = UserService(
      apiClient: apiClient,
      prefs: prefs,
    );
    await userService.initialize();
    AppLogger.info('UserService initialized');

    final authService = AuthService(
      firebaseAuth: firebaseAuth,
      tokenManager: tokenManager,
      userService: userService,
    );
    await authService.initialize();
    AppLogger.info('AuthService initialized');

    runApp(
      MyApp(
        authService: authService,
        tokenManager: tokenManager,
      ),
    );
  } catch (e) {
    AppLogger.error('Failed to initialize app', e);
    runApp(const ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final TokenManager tokenManager;

  const MyApp({
    Key? key,
    required this.authService,
    required this.tokenManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: tokenManager),
      ],
      child: MaterialApp.router(
        title: 'Coopvest Africa',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        routerConfig: AppRouter(authService: authService).getRouter(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize app',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your configuration and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Restart app
                },
                child: const Text('Restart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
