import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import 'glass_card.dart';

class GlassTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final bool obscureText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;

  const GlassTextField({
    super.key,
    this.label,
    this.hint,
    this.obscureText = false,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 16,
          blur: 8,
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.5),
          child: TextFormField(
            controller: controller,
            onChanged: onChanged,
            validator: validator,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark
                    ? Colors.white38
                    : AppTheme.textSecondary.withValues(alpha: 0.7),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              prefixIcon: prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: prefixIcon,
                    )
                  : null,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
