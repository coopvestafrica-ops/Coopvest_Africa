import 'package:flutter/material.dart';

class CustomRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final bool enablePullDown;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.enablePullDown = true,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: 40.0,
      strokeWidth: 3.0,
      color: Theme.of(context).primaryColor,
      child: child,
    );
  }
}
