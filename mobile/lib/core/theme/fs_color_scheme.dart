import 'package:flutter/material.dart';

class FSColorScheme extends ThemeExtension<FSColorScheme> {
  final Color background;
  final Color surface;
  final Color card;
  final Color elevated;
  final Color border;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color teal;
  final Color positive;
  final Color negative;
  final Color warning;
  final Color info;
  final Color purple;

  final Color tealDim;
  final Color redDim;
  final Color amberDim;
  final Color infoDim;
  final Color purpleDim;
  final Color greenDim;

  const FSColorScheme({
    required this.background,
    required this.surface,
    required this.card,
    required this.elevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.teal,
    required this.positive,
    required this.negative,
    required this.warning,
    required this.info,
    required this.purple,
    required this.tealDim,
    required this.redDim,
    required this.amberDim,
    required this.infoDim,
    required this.purpleDim,
    required this.greenDim,
  });

  static const dark = FSColorScheme(
    background: Color(0xFF07111F),
    surface: Color(0xFF0F1B2E),
    card: Color(0xFF132238),
    elevated: Color(0xFF182B45),
    border: Color(0x14FFFFFF),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    textTertiary: Color(0xFF475569),
    teal: Color(0xFF14B8A6),
    positive: Color(0xFF22C55E),
    negative: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF3B82F6),
    purple: Color(0xFF8B5CF6),
    tealDim: Color(0x2014B8A6),
    redDim: Color(0x20EF4444),
    amberDim: Color(0x20F59E0B),
    infoDim: Color(0x203B82F6),
    purpleDim: Color(0x208B5CF6),
    greenDim: Color(0x2022C55E),
  );

  static const light = FSColorScheme(
    background: Color(0xFFF7F9FC),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    elevated: Color(0xFFF0F4F8),
    border: Color(0x14000000),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textTertiary: Color(0xFF94A3B8),
    teal: Color(0xFF2AB5A0),
    positive: Color(0xFF16A34A),
    negative: Color(0xFFDC2626),
    warning: Color(0xFFD97706),
    info: Color(0xFF2563EB),
    purple: Color(0xFF7C3AED),
    tealDim: Color(0x1A2AB5A0),
    redDim: Color(0x1ADC2626),
    amberDim: Color(0x1AD97706),
    infoDim: Color(0x1A2563EB),
    purpleDim: Color(0x1A7C3AED),
    greenDim: Color(0x1A16A34A),
  );

  Color amountColor(double amount) {
    if (amount > 0) return positive;
    if (amount < 0) return negative;
    return textSecondary;
  }

  @override
  FSColorScheme copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? elevated,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? teal,
    Color? positive,
    Color? negative,
    Color? warning,
    Color? info,
    Color? purple,
    Color? tealDim,
    Color? redDim,
    Color? amberDim,
    Color? infoDim,
    Color? purpleDim,
    Color? greenDim,
  }) =>
      FSColorScheme(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        card: card ?? this.card,
        elevated: elevated ?? this.elevated,
        border: border ?? this.border,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textTertiary: textTertiary ?? this.textTertiary,
        teal: teal ?? this.teal,
        positive: positive ?? this.positive,
        negative: negative ?? this.negative,
        warning: warning ?? this.warning,
        info: info ?? this.info,
        purple: purple ?? this.purple,
        tealDim: tealDim ?? this.tealDim,
        redDim: redDim ?? this.redDim,
        amberDim: amberDim ?? this.amberDim,
        infoDim: infoDim ?? this.infoDim,
        purpleDim: purpleDim ?? this.purpleDim,
        greenDim: greenDim ?? this.greenDim,
      );

  @override
  FSColorScheme lerp(FSColorScheme other, double t) => FSColorScheme(
        background: Color.lerp(background, other.background, t)!,
        surface: Color.lerp(surface, other.surface, t)!,
        card: Color.lerp(card, other.card, t)!,
        elevated: Color.lerp(elevated, other.elevated, t)!,
        border: Color.lerp(border, other.border, t)!,
        textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
        textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
        textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
        teal: Color.lerp(teal, other.teal, t)!,
        positive: Color.lerp(positive, other.positive, t)!,
        negative: Color.lerp(negative, other.negative, t)!,
        warning: Color.lerp(warning, other.warning, t)!,
        info: Color.lerp(info, other.info, t)!,
        purple: Color.lerp(purple, other.purple, t)!,
        tealDim: Color.lerp(tealDim, other.tealDim, t)!,
        redDim: Color.lerp(redDim, other.redDim, t)!,
        amberDim: Color.lerp(amberDim, other.amberDim, t)!,
        infoDim: Color.lerp(infoDim, other.infoDim, t)!,
        purpleDim: Color.lerp(purpleDim, other.purpleDim, t)!,
        greenDim: Color.lerp(greenDim, other.greenDim, t)!,
      );
}

extension BuildContextFSX on BuildContext {
  FSColorScheme get fsc => Theme.of(this).extension<FSColorScheme>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
