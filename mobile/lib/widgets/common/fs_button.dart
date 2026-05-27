import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';

enum FSButtonStyle { primary, ghost, danger, secondary }

class FSButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final FSButtonStyle style;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final double? height;

  const FSButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = FSButtonStyle.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;

    final (bg, fg, borderColor) = switch (style) {
      FSButtonStyle.primary   => (c.teal, Colors.white, c.teal),
      FSButtonStyle.ghost     => (Colors.transparent, c.teal, c.teal),
      FSButtonStyle.danger    => (c.redDim, c.negative, c.negative),
      FSButtonStyle.secondary => (c.surface, c.textSecondary, c.border),
    };

    Widget child = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          );

    Widget button = Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height ?? 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: style == FSButtonStyle.primary ? 0 : 1),
          ),
          child: Center(child: child),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
