import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

enum FSButtonStyle { primary, ghost, danger }

class FSButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final FSButtonStyle style;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const FSButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = FSButtonStyle.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (style) {
      FSButtonStyle.primary => (FSColors.teal, const Color(0xFF0F1117), FSColors.teal),
      FSButtonStyle.ghost   => (Colors.transparent, FSColors.teal, FSColors.teal),
      FSButtonStyle.danger  => (FSColors.redDim, FSColors.negative, FSColors.negative),
    };

    Widget child = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg,
            ),
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
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Center(child: child),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
