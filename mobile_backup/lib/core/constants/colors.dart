import 'package:flutter/material.dart';

class FSColors {
  FSColors._();

  static const background   = Color(0xFF0F1117);
  static const card         = Color(0xFF171B26);
  static const tertiary     = Color(0xFF1E2333);

  static const textPrimary   = Color(0xFFE8EDF5);
  static const textSecondary = Color(0xFF8892A4);
  static const textTertiary  = Color(0xFF535D6E);

  static const border = Color(0x0FFFFFFF);

  static const teal     = Color(0xFF3ECFB2);
  static const positive = Color(0xFF2DD4A7);
  static const negative = Color(0xFFF16B6B);
  static const warning  = Color(0xFFF5A623);
  static const info     = Color(0xFF5B9CF6);
  static const purple   = Color(0xFF9B8FE8);

  static const tealDim   = Color(0x1F3ECFB2);
  static const redDim    = Color(0x1FF16B6B);
  static const amberDim  = Color(0x1FF5A623);
  static const infoDim   = Color(0x1F5B9CF6);
  static const purpleDim = Color(0x1F9B8FE8);

  static Color amountColor(double amount) {
    if (amount > 0) return positive;
    if (amount < 0) return negative;
    return textSecondary;
  }
}
