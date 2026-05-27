import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';
import '../../core/utils/currency_formatter.dart';

class FSAmountDisplay extends StatelessWidget {
  final double amount;
  final double fontSize;
  final FontWeight fontWeight;
  final bool showSign;
  final bool compact;

  const FSAmountDisplay({
    super.key,
    required this.amount,
    this.fontSize = 20,
    this.fontWeight = FontWeight.w500,
    this.showSign = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final color = c.amountColor(amount);
    final text = compact ? formatINRCompact(amount.abs()) : formatINR(amount.abs());
    final prefix = showSign && amount > 0 ? '+' : (amount < 0 ? '-' : '');

    return Text(
      '$prefix$text',
      style: GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}
