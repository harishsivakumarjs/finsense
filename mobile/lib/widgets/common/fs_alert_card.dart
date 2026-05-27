import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';

class FSAlertCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;

  const FSAlertCard({
    super.key,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final alertColor = color ?? c.warning;
    return Container(
      decoration: BoxDecoration(
        color: alertColor.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: alertColor, width: 3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: alertColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: c.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
