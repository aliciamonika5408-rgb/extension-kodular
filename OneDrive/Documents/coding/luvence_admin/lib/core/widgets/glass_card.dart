import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Glassmorphism card matching web admin's C style
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;
  final double blurAmount;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.borderColor,
    this.gradientColors,
    this.onTap,
    this.blurAmount = 12,
  });

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: const Alignment(-0.8, -1),
              end: const Alignment(0.8, 1),
              colors: gradientColors ?? [
                const Color(0x801E2332),
                const Color(0x990A0C14),
              ],
            ),
            border: Border.all(
              color: borderColor ?? LuvColors.border,
              width: 1,
            ),
            boxShadow: LuvColors.cardShadow,
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}
