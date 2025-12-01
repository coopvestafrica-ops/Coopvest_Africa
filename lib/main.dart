import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:ui';

import 'core/config/app_config.dart';
import 'core/services/auth_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/navigation_service.dart';
import 'core/services/error_reporting_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/notification_provider.dart';
import 'features/dashboard/presentation/providers/dashboard_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/providers/navigation_provider.dart';
import 'core/utils/connectivity_checker.dart';
import 'core/utils/service_locator.dart';
import 'core/widgets/loading_screen.dart';
import 'features/dashboard/data/services/dashboard_service.dart';
import 'core/routes/app_routes.dart';

Future<void> main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseService.instance.initialize();

  // Initialize error reporting service
  final errorReportingService = ErrorReportingService.instance;
  await errorReportingService.initialize(
    enableCrashlytics: true,
    captureStackTraces: true,
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');

    // Report to crash analytics service
    ErrorReportingService.instance.reportException(
      details.exception,
      details.stack,
      reason: 'Flutter error caught',
      fatal: false,
    );
  };

  // Initialize all services
  final serviceLocator = ServiceLocator.instance;
  await serviceLocator.initializeServices();

  // Set up service disposal for app termination
  WidgetsBinding.instance.addObserver(LifecycleEventHandler(
    detached: () async {
      await serviceLocator.disposeServices();
    },
  ));

  // Get initial app state
  final prefs = serviceLocator.get<SharedPreferences>();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize NavigationService with global key
  // This key is managed by NavigationService and not exposed to the app
  final navigationService = NavigationService.instance;
  navigationService.initialize(GlobalKey<NavigatorState>());

  // Set up global error handler for platform errors (non-Flutter errors)
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorReportingService.instance.reportException(
      error,
      stack,
      reason: 'Platform error (non-Flutter)',
      fatal: true,
    );
    return true; // Indicate error has been handled
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService.instance),
        ),
        ChangeNotifierProvider(
          create: (_) => ConnectivityProvider(ConnectivityChecker()),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(
            serviceLocator.get<DashboardService>(),
            prefs,
          ),
          lazy: false, // Initialize immediately
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => NavigationProvider(),
        ),
      ],
      child: CoopvestApp(
        hasSeenOnboarding: hasSeenOnboarding,
      ),
    ),
  );
}

// Navigation observer to track screen transitions
class AppNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Screen pushed: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Screen popped: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugPrint('Screen replaced: ${newRoute?.settings.name}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Screen removed: ${route.settings.name}');
  }
}

class CoopvestApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  const CoopvestApp({
    super.key,
    required this.hasSeenOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final navigationService = NavigationService.instance;
    
    return MaterialApp(
      title: AppConfig.appName,
      navigatorKey: navigationService.navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      navigatorObservers: [AppNavigationObserver()],
      initialRoute: _initialRoute,
      supportedLocales: const [
        Locale('en', ''), // English
      ],
      builder: (context, child) {
        // Get auth state
        final authState = context.watch<AuthProvider>();

        // Show loading screen while checking auth
        if (authState.isAuthenticating ||
            authState.status == AuthStatus.initial) {
          return const LoadingScreen();
        }

        // If not authenticated, navigate to signup using Navigator
        // Prefer using Navigator.of(context) instead of global key
        if (!authState.isAuthenticated &&
            ModalRoute.of(context)?.settings.name != '/signup') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              // Use context-based navigation (preferred)
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/signup',
                  (route) => false,
                );
              }
            } catch (_) {
              // ignore navigation errors during app initialization
            }
          });
        }

        return MediaQuery(
          // Prevent text scaling beyond 1.2
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              clampDouble(MediaQuery.of(context).textScaleFactor, 0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
      onGenerateRoute: (settings) {
        // Use the new lazy-loading route generator
        // Get auth provider from context if available
        final authProvider = context.mounted
            ? Provider.of<AuthProvider>(context, listen: false)
            : null;
        
        if (authProvider == null) {
          debugPrint('⚠️ AuthProvider not available for route: ${settings.name}');
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        return AppRouteGenerator.generateRoute(settings, authProvider);
      },
      debugShowCheckedModeBanner: false,
    );
  }

  String get _initialRoute => hasSeenOnboarding ? '/dashboard' : '/onboarding';

  double clampDouble(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}

/// Handles app lifecycle events for cleanup
class LifecycleEventHandler extends WidgetsBindingObserver {
  final Future<void> Function()? resumed;
  final Future<void> Function()? inactive;
  final Future<void> Function()? paused;
  final Future<void> Function()? detached;

  LifecycleEventHandler({
    this.resumed,
    this.inactive,
    this.paused,
    this.detached,
  });

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        if (resumed != null) await resumed!();
        break;
      case AppLifecycleState.inactive:
        if (inactive != null) await inactive!();
        break;
      case AppLifecycleState.paused:
        if (paused != null) await paused!();
        break;
      case AppLifecycleState.detached:
        if (detached != null) await detached!();
        break;
      default:
        break;
    }
  }
}
