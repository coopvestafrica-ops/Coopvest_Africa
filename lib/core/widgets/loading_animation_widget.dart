import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingAnimationWidget extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const LoadingAnimationWidget({
    super.key,
    this.width = double.infinity,
    this.height = 12.0,
    this.shapeBorder = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          shape: shapeBorder,
          color: Colors.grey[400]!,
        ),
      ),
    );
  }
}

class ListItemLoadingAnimation extends StatelessWidget {
  const ListItemLoadingAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingAnimationWidget(
            width: 48,
            height: 48,
            shapeBorder: const CircleBorder(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingAnimationWidget(width: 120),
                const SizedBox(height: 8),
                LoadingAnimationWidget(width: double.infinity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
