import 'package:flutter/material.dart';

// Static constants matching FSColorScheme.dark — used as fallbacks.
// Prefer context.fsc.xxx in widget code for proper theme support.
class FSColors {
  FSColors._();

  static const background = Color(0xFF07111F);
  static const surface    = Color(0xFF0F1B2E);
  static const card       = Color(0xFF132238);
  static const elevated   = Color(0xFF182B45);
  static const tertiary   = Color(0xFF0F1B2E);

  static const textPrimary   = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const textTertiary  = Color(0xFF475569);

  static const border = Color(0x14FFFFFF);

  static const teal     = Color(0xFF14B8A6);
  static const positive = Color(0xFF22C55E);
  static const negative = Color(0xFFEF4444);
  static const warning  = Color(0xFFF59E0B);
  static const info     = Color(0xFF3B82F6);
  static const purple   = Color(0xFF8B5CF6);

  static const tealDim   = Color(0x2014B8A6);
  static const redDim    = Color(0x20EF4444);
  static const amberDim  = Color(0x20F59E0B);
  static const infoDim   = Color(0x203B82F6);
  static const purpleDim = Color(0x208B5CF6);
  static const greenDim  = Color(0x2022C55E);

  static Color amountColor(double amount) {
    if (amount > 0) return positive;
    if (amount < 0) return negative;
    return textSecondary;
  }
}
