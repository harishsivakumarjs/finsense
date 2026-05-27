import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';

class FSMetricCard extends StatelessWidget {
  final String label;
  final double value;
  final Color accentColor;
  final String? subtitle;
  final bool compact;
  final bool isAmount;

  const FSMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.accentColor,
    this.subtitle,
    this.compact = false,
    this.isAmount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FSColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          top: BorderSide(color: accentColor, width: 2),
          left: const BorderSide(color: FSColors.border),
          right: const BorderSide(color: FSColors.border),
          bottom: const BorderSide(color: FSColors.border),
        ),
      ),
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: FSColors.textTertiary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAmount ? formatINRCompact(value) : value.toStringAsFixed(1),
            style: GoogleFonts.jetBrainsMono(
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.w500,
              color: accentColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: FSColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
