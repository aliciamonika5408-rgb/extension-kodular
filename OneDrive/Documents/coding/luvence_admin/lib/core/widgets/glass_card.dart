import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';

/// Premium glassmorphism card matching the web admin's SectionCard design.
///
/// New parameters:
/// - [accentBar]    — shows a gold gradient line at the top (like web admin's `accent` prop)
/// - [glowColor]    — ambient glow under the card (null = default shadow)
/// - [onTap]        — adds a 0.97 scale press animation with haptic feedback
/// - [margin]       — outer margin (default: bottom-only 16px)
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;
  final double blurAmount;
  final bool accentBar;
  final Color? glowColor;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.borderColor,
    this.gradientColors,
    this.onTap,
    this.blurAmount = 10,
    this.accentBar = false,
    this.glowColor,
    this.margin,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveShadow = widget.glowColor != null
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: widget.glowColor!.withValues(alpha: 0.08),
              blurRadius: 28,
              spreadRadius: -4,
            ),
          ]
        : LuvColors.cardShadow;

    final card = Container(
      margin: widget.margin ?? const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: effectiveShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blurAmount, sigmaY: widget.blurAmount),
          child: Container(
            padding: widget.padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                begin: const Alignment(-0.8, -1),
                end: const Alignment(0.8, 1),
                colors: widget.gradientColors ??
                    [
                      const Color(0x801E2332),
                      const Color(0x990A0C14),
                    ],
              ),
              border: Border.all(
                color: widget.borderColor ?? LuvColors.border,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Gold accent bar at top
                if (widget.accentBar)
                  Positioned(
                    top: -(widget.padding?.resolve(TextDirection.ltr).top ?? 20),
                    left: -(widget.padding?.resolve(TextDirection.ltr).left ?? 20),
                    right: -(widget.padding?.resolve(TextDirection.ltr).right ?? 20),
                    child: Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            LuvColors.accent,
                            LuvColors.accentDark,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.6, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x40D4A574),
                            blurRadius: 12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Actual content
                widget.child,
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) {
          HapticFeedback.selectionClick();
          _pressController.forward();
        },
        onTapUp: (_) {
          _pressController.reverse();
          widget.onTap!();
        },
        onTapCancel: () => _pressController.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (_, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: card,
        ),
      );
    }
    return card;
  }
}
