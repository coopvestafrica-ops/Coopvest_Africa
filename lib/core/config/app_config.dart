class AppConfig {
  static const String appName = 'Coopvest Africa';
  static const String appVersion = '1.0.0';
  static const String baseUrl = 'https://api.coopvest.africa';
  
  // Environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  static bool get isProduction => environment == 'production';
  
  // API endpoints
  static const String authEndpoint = '/auth';
  static const String loansEndpoint = '/loans';
  static const String walletEndpoint = '/wallet';
  static const String investmentsEndpoint = '/investments';
  
  // Timeouts
  static const int apiTimeoutSeconds = 30;
  static const int connectTimeoutSeconds = 10;
  
  // Cache durations
  static const Duration cacheDuration = Duration(minutes: 5);
  
  // Feature flags
  static const bool enableBiometrics = true;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
}
