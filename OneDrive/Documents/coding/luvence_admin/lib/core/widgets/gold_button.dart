import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';

enum GoldButtonStyle { primary, secondary, danger }

class GoldButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final GoldButtonStyle style;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;
  final double? height;

  const GoldButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = GoldButtonStyle.primary,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
    this.height,
  });

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.style) {
      case GoldButtonStyle.primary:
        return LuvColors.accent;
      case GoldButtonStyle.danger:
        return LuvColors.errorBg;
      case GoldButtonStyle.secondary:
        return Colors.transparent;
    }
  }

  Color get _textColor {
    switch (widget.style) {
      case GoldButtonStyle.primary:
        return LuvColors.background;
      case GoldButtonStyle.danger:
        return LuvColors.error;
      case GoldButtonStyle.secondary:
        return LuvColors.textTertiary;
    }
  }

  Border get _border {
    switch (widget.style) {
      case GoldButtonStyle.primary:
        return Border.all(color: Colors.transparent);
      case GoldButtonStyle.danger:
        return Border.all(color: LuvColors.error.withValues(alpha: 0.1));
      case GoldButtonStyle.secondary:
        return Border.all(color: LuvColors.borderLight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => _controller.forward(),
        onTapUp: isDisabled ? null : (_) {
          _controller.reverse();
          HapticFeedback.lightImpact();
          widget.onPressed?.call();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isDisabled ? 0.5 : 1.0,
          child: Container(
            height: widget.height ?? 48,
            width: widget.expanded ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              gradient: widget.style == GoldButtonStyle.primary
                  ? LuvColors.goldGradient
                  : null,
              color: widget.style != GoldButtonStyle.primary ? _bgColor : null,
              borderRadius: BorderRadius.circular(14),
              border: _border,
              boxShadow: widget.style == GoldButtonStyle.primary
                  ? [
                      BoxShadow(
                        color: LuvColors.accent.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: _textColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
