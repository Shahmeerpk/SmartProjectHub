import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Neumorphic-style container: soft inner shadow + outer highlight.
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool isPressed;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.isPressed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppTheme.surfaceDark : AppTheme.surface;
    final light = isDark ? const Color(0xFF475569) : const Color(0xFFF8FAFC);
    final dark = isDark ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1);

    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: dark.withValues(alpha: 0.25),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                  spreadRadius: -1,
                ),
              ]
            : [
                BoxShadow(
                  color: dark.withValues(alpha: 0.35),
                  offset: const Offset(6, 6),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: light.withValues(alpha: 0.9),
                  offset: const Offset(-4, -4),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
      ),
      child: child,
    );
  }
}
