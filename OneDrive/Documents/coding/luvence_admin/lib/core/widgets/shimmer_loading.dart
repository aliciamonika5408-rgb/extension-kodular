import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/colors.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      gradient: LuvColors.shimmerGradient,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: LuvColors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  /// Shimmer card placeholder
  static Widget card({double height = 120}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShimmerLoading(height: height, borderRadius: 20),
    );
  }

  /// Shimmer stat row
  static Widget statRow() {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => const ShimmerLoading(width: 160, height: 130, borderRadius: 20),
      ),
    );
  }

  /// Shimmer list
  static Widget list({int count = 5, double itemHeight = 80}) {
    return Column(
      children: List.generate(count, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerLoading(height: itemHeight, borderRadius: 16),
      )),
    );
  }
}
