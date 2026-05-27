import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';

class FSLoadingSkeleton extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;

  const FSLoadingSkeleton({
    super.key,
    required this.height,
    this.width,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: FSColors.tertiary,
        borderRadius: BorderRadius.circular(radius),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
      duration: 1200.ms,
      color: FSColors.textTertiary.withAlpha(40),
    );
  }
}

class FSSkeletonCard extends StatelessWidget {
  const FSSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FSColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FSColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FSLoadingSkeleton(height: 12, width: 80),
          SizedBox(height: 10),
          FSLoadingSkeleton(height: 24, width: 140),
          SizedBox(height: 6),
          FSLoadingSkeleton(height: 10, width: 100),
        ],
      ),
    );
  }
}

class FSSkeletonList extends StatelessWidget {
  final int count;
  const FSSkeletonList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: FSColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FSColors.border),
          ),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                FSLoadingSkeleton(height: 36, width: 36, radius: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FSLoadingSkeleton(height: 12, width: 120),
                      SizedBox(height: 6),
                      FSLoadingSkeleton(height: 10, width: 80),
                    ],
                  ),
                ),
                FSLoadingSkeleton(height: 16, width: 70),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: i * 60))),
    );
  }
}
