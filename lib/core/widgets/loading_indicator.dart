import 'package:flutter/material.dart';

/// A customizable loading indicator widget that provides different styles of loading animations.
/// Can be used as a full-screen loader, inline loader, or with custom overlay.
class LoadingIndicator extends StatelessWidget {
  /// The size of the loading indicator
  final double size;

  /// The color of the loading indicator. If null, uses the primary color from theme
  final Color? color;

  /// Optional text to display below the loading indicator
  final String? message;

  /// Whether to show the loading indicator on a dark background overlay
  final bool withOverlay;

  /// The opacity of the overlay background (if withOverlay is true)
  final double overlayOpacity;

  /// The style of loading indicator to use
  final LoadingStyle style;

  /// The thickness of the circular progress indicator (if applicable)
  final double strokeWidth;

  /// Text style for the message
  final TextStyle? messageStyle;

  /// Optional padding around the loading indicator
  final EdgeInsets? padding;

  /// Creates a loading indicator widget
  const LoadingIndicator({
    super.key,
    this.size = 40,
    this.color,
    this.message,
    this.withOverlay = false,
    this.overlayOpacity = 0.7,
    this.style = LoadingStyle.circular,
    this.strokeWidth = 4.0,
    this.messageStyle,
    this.padding,
  });

  /// Creates a full-screen loading indicator with overlay
  factory LoadingIndicator.fullScreen({
    String? message,
    Color? color,
    LoadingStyle style = LoadingStyle.circular,
    double overlayOpacity = 0.7,
    TextStyle? messageStyle,
  }) {
    return LoadingIndicator(
      size: 50,
      color: color,
      message: message,
      withOverlay: true,
      overlayOpacity: overlayOpacity,
      style: style,
      messageStyle: messageStyle,
      padding: const EdgeInsets.all(24),
    );
  }

  /// Creates a small inline loading indicator
  factory LoadingIndicator.small({
    Color? color,
    LoadingStyle style = LoadingStyle.circular,
    double size = 24,
  }) {
    return LoadingIndicator(
      size: size,
      color: color,
      style: style,
      strokeWidth: 2.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingColor = color ?? theme.colorScheme.primary;
    
    Widget indicator;
    switch (style) {
      case LoadingStyle.circular:
        indicator = SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
          ),
        );
      case LoadingStyle.adaptive:
        indicator = SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator.adaptive(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
          ),
        );
      case LoadingStyle.linear:
        indicator = SizedBox(
          width: size * 2,
          child: LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
          ),
        );
      case LoadingStyle.threeBounce:
        indicator = _ThreeBouncingDots(
          size: size,
          color: loadingColor,
        );
      case LoadingStyle.pulsing:
        indicator = _PulsingLoader(
          size: size,
          color: loadingColor,
        );
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: messageStyle ??
                theme.textTheme.bodyMedium?.copyWith(
                  color: withOverlay ? Colors.white : null,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (!withOverlay) {
      return Padding(
        padding: padding ?? EdgeInsets.zero,
        child: content,
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.black.withOpacity(overlayOpacity),
        child: Center(
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: content,
          ),
        ),
      ),
    );
  }
}

/// The style of loading indicator to display
enum LoadingStyle {
  /// A standard circular progress indicator
  circular,

  /// A platform-adaptive circular progress indicator
  adaptive,

  /// A horizontal linear progress indicator
  linear,

  /// Three bouncing dots animation
  threeBounce,

  /// A pulsing circle animation
  pulsing,
}

/// A three bouncing dots loading animation
class _ThreeBouncingDots extends StatefulWidget {
  final double size;
  final Color color;

  const _ThreeBouncingDots({
    required this.size,
    required this.color,
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

/// A pulsing circle loading animation
class _PulsingLoader extends StatefulWidget {
  final double size;
  final Color color;

  const _PulsingLoader({
    required this.size,
    required this.color,
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
            color: widget.color.withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}