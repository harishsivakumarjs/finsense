import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';
import '../../core/utils/currency_formatter.dart';

class FSMetricCard extends StatelessWidget {
  final String label;
  final double value;
  final Color? accentColor;
  final String? subtitle;
  final bool compact;
  final bool isAmount;
  final Widget? trailing;

  final bool showExact;

  const FSMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.accentColor,
    this.subtitle,
    this.compact = false,
    this.isAmount = true,
    this.showExact = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final accent = accentColor ?? c.teal;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: c.textTertiary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAmount ? (showExact ? formatINR(value) : formatINRCompact(value)) : value.toStringAsFixed(0),
            style: GoogleFonts.jetBrainsMono(
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: c.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
