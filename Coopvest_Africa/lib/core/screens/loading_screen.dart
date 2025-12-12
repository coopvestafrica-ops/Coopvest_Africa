import 'package:flutter/material.dart';

/// A customizable loading screen that can display various loading states
/// with animations and progress indicators.
class LoadingScreen extends StatelessWidget {
  /// The message to display below the loading indicator
  final String? message;

  /// Optional logo or image to display above the loading indicator
  final Widget? logo;

  /// Progress value between 0.0 and 1.0 for determinate loading
  final double? progress;

  /// Color of the loading indicator
  final Color? color;

  /// Background color of the screen
  final Color? backgroundColor;

  /// Style of the loading indicator
  final LoadingStyle style;

  /// Whether to show a dismiss button
  final bool showDismissButton;

  /// Callback when dismiss button is pressed
  final VoidCallback? onDismiss;

  /// Size of the loading indicator
  final double indicatorSize;

  /// Custom theme for text elements
  final LoadingTextTheme? textTheme;

  /// Additional widgets to display below the message
  final List<Widget>? additionalContent;

  /// Creates a loading screen
  const LoadingScreen({
    super.key,
    this.message,
    this.logo,
    this.progress,
    this.color,
    this.backgroundColor,
    this.style = LoadingStyle.circular,
    this.showDismissButton = false,
    this.onDismiss,
    this.indicatorSize = 48.0,
    this.textTheme,
    this.additionalContent,
  });

  /// Creates a branded loading screen with logo
  factory LoadingScreen.branded({
    required Widget logo,
    String? message,
    Color? backgroundColor,
    LoadingTextTheme? textTheme,
  }) {
    return LoadingScreen(
      logo: logo,
      message: message,
      backgroundColor: backgroundColor,
      textTheme: textTheme,
      style: LoadingStyle.circular,
    );
  }

  /// Creates a progress loading screen
  factory LoadingScreen.progress({
    required double progress,
    required String message,
    Color? color,
    LoadingTextTheme? textTheme,
  }) {
    return LoadingScreen(
      progress: progress,
      message: message,
      color: color,
      textTheme: textTheme,
      style: LoadingStyle.linear,
    );
  }

  /// Creates a dismissible loading screen
  factory LoadingScreen.dismissible({
    String? message,
    required VoidCallback onDismiss,
    Color? backgroundColor,
    LoadingTextTheme? textTheme,
  }) {
    return LoadingScreen(
      message: message,
      backgroundColor: backgroundColor,
      textTheme: textTheme,
      showDismissButton: true,
      onDismiss: onDismiss,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingColor = color ?? theme.colorScheme.primary;
    final bgColor = backgroundColor ?? theme.scaffoldBackgroundColor;
    final textStyles = textTheme ?? LoadingTextTheme.fromTheme(theme);
    
    return PopScope(
      canPop: showDismissButton,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (logo != null) ...[
                        logo!,
                        const SizedBox(height: 48),
                      ],
                      _buildLoadingIndicator(loadingColor),
                      if (message != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          message!,
                          style: textStyles.messageStyle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (additionalContent != null) ...[
                        const SizedBox(height: 32),
                        ...additionalContent!,
                      ],
                    ],
                  ),
                ),
              ),
              if (showDismissButton)
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onDismiss,
                    tooltip: 'Dismiss',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(Color color) {
    switch (style) {
      case LoadingStyle.circular:
        return SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(color),
            value: progress,
          ),
        );
      case LoadingStyle.linear:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(color),
            value: progress,
          ),
        );
      case LoadingStyle.adaptive:
        return SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation<Color>(color),
            value: progress,
          ),
        );
      case LoadingStyle.threeBounce:
        return _ThreeBouncingDots(
          color: color,
          size: indicatorSize,
        );
      case LoadingStyle.pulse:
        return _PulsingLoader(
          color: color,
          size: indicatorSize,
        );
    }
  }
}

/// Styles for loading indicators
enum LoadingStyle {
  circular,
  linear,
  adaptive,
  threeBounce,
  pulse,
}

/// Theme for text elements in the loading screen
class LoadingTextTheme {
  final TextStyle messageStyle;
  final TextStyle? subtitleStyle;
  final TextStyle? buttonStyle;

  const LoadingTextTheme({
    required this.messageStyle,
    this.subtitleStyle,
    this.buttonStyle,
  });

  /// Creates a loading text theme from the current theme
  factory LoadingTextTheme.fromTheme(ThemeData theme) {
    return LoadingTextTheme(
      messageStyle: theme.textTheme.bodyLarge ?? const TextStyle(),
      subtitleStyle: theme.textTheme.bodyMedium,
      buttonStyle: theme.textTheme.labelLarge,
    );
  }
}

/// Three bouncing dots loading animation
class _ThreeBouncingDots extends StatefulWidget {
  final Color color;
  final double size;

  const _ThreeBouncingDots({
    required this.color,
    required this.size,
  });

  @override
  State<_ThreeBouncingDots> createState() => _ThreeBouncingDotsState();
}

class _ThreeBouncingDotsState extends State<_ThreeBouncingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.0),
          weight: 50,
        ),
      ]).animate(controller);
    }).toList();

    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -widget.size * 0.3 * _animations[index].value),
                child: Container(
                  width: widget.size * 0.25,
                  height: widget.size * 0.25,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

/// Pulsing circle loading animation
class _PulsingLoader extends StatefulWidget {
  final Color color;
  final double size;

  const _PulsingLoader({
    required this.color,
    required this.size,
  });

  @override
  State<_PulsingLoader> createState() => _PulsingLoaderState();
}

class _PulsingLoaderState extends State<_PulsingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.3),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withAlpha((_animation.value * 255).round()),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
