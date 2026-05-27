import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class FSTextStyles {
  FSTextStyles._();

  static TextStyle get amountLarge => GoogleFonts.jetBrainsMono(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: FSColors.textPrimary,
      );

  static TextStyle get amountMedium => GoogleFonts.jetBrainsMono(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: FSColors.textPrimary,
      );

  static TextStyle get amountSmall => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: FSColors.textPrimary,
      );

  static TextStyle get heading => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: FSColors.textPrimary,
      );

  static TextStyle get subheading => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: FSColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: FSColors.textSecondary,
      );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: FSColors.textTertiary,
      );

  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: FSColors.textTertiary,
        letterSpacing: 0.8,
      );

  static TextStyle amount(double value) => amountMedium.copyWith(
        color: FSColors.amountColor(value),
      );
}
