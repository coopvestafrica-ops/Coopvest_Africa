import 'package:flutter/material.dart';

/// A screen to display various types of errors with customizable actions.
class ErrorScreen extends StatelessWidget {
  /// The title of the error screen
  final String? title;

  /// The error message to display
  final String message;

  /// The optional asset path for an animation to display (Lottie format)
  final String? animationAsset;

  /// The primary action button text
  final String primaryButtonText;

  /// Callback when the primary button is pressed
  final VoidCallback onPrimaryButtonPressed;

  /// Optional secondary action button text
  final String? secondaryButtonText;

  /// Optional callback when the secondary button is pressed
  final VoidCallback? onSecondaryButtonPressed;

  /// Optional error details for technical information
  final String? technicalDetails;

  /// Whether to show a home button in the app bar
  final bool showHomeButton;

  /// Optional custom widget to display instead of the default animation
  final Widget? customErrorWidget;

  const ErrorScreen({
    super.key,
    this.title,
    required this.message,
    this.animationAsset,
    required this.primaryButtonText,
    required this.onPrimaryButtonPressed,
    this.secondaryButtonText,
    this.onSecondaryButtonPressed,
    this.technicalDetails,
    this.showHomeButton = true,
    this.customErrorWidget,
  }) : assert(
          animationAsset == null || customErrorWidget == null,
          'Cannot provide both animationAsset and customErrorWidget',
        );

  /// Factory constructor for network error screen
  factory ErrorScreen.network({
    required VoidCallback onRetry,
    String? message,
    bool showHomeButton = true,
  }) {
    return ErrorScreen(
      title: 'Connection Error',
      message: message ?? 'Unable to connect to the server. Please check your internet connection.',
      animationAsset: 'assets/animations/network_error.json',
      primaryButtonText: 'Retry',
      onPrimaryButtonPressed: onRetry,
      showHomeButton: showHomeButton,
    );
  }

  /// Factory constructor for not found error screen
  factory ErrorScreen.notFound({
    required VoidCallback onBackPressed,
    String? message,
    bool showHomeButton = true,
  }) {
    return ErrorScreen(
      title: 'Not Found',
      message: message ?? 'The requested resource could not be found.',
      animationAsset: 'assets/animations/not_found.json',
      primaryButtonText: 'Go Back',
      onPrimaryButtonPressed: onBackPressed,
      showHomeButton: showHomeButton,
    );
  }

  /// Factory constructor for permission denied error screen
  factory ErrorScreen.permissionDenied({
    required VoidCallback onBackPressed,
    String? message,
    bool showHomeButton = true,
  }) {
    return ErrorScreen(
      title: 'Access Denied',
      message: message ?? 'You don\'t have permission to access this resource.',
      animationAsset: 'assets/animations/permission_denied.json',
      primaryButtonText: 'Go Back',
      onPrimaryButtonPressed: onBackPressed,
      showHomeButton: showHomeButton,
    );
  }

  /// Factory constructor for maintenance mode screen
  factory ErrorScreen.maintenance({
    required VoidCallback onRefresh,
    String? message,
    bool showHomeButton = false,
  }) {
    return ErrorScreen(
      title: 'Under Maintenance',
      message: message ?? 'We\'re currently performing maintenance. Please try again later.',
      animationAsset: 'assets/animations/maintenance.json',
      primaryButtonText: 'Refresh',
      onPrimaryButtonPressed: onRefresh,
      showHomeButton: showHomeButton,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        onPrimaryButtonPressed();
      },
      child: Scaffold(
        appBar: showHomeButton
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              )
            : null,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (customErrorWidget != null)
                        customErrorWidget!
                      else
                        const Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red,
                        ),
                      const SizedBox(height: 32),
                      if (title != null) ...[
                        Text(
                          title!,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      if (technicalDetails != null) ...[
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Technical Details'),
                                content: SingleChildScrollView(
                                  child: Text(technicalDetails!),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Text(
                            'Show Technical Details',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  decoration: TextDecoration.underline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: onPrimaryButtonPressed,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(primaryButtonText),
                    ),
                    if (secondaryButtonText != null &&
                        onSecondaryButtonPressed != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: onSecondaryButtonPressed,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(secondaryButtonText!),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
