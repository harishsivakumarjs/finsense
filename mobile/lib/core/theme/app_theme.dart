import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'fs_color_scheme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(FSColorScheme.dark, Brightness.dark);
  static ThemeData get light => _build(FSColorScheme.light, Brightness.light);

  static ThemeData _build(FSColorScheme c, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: c.background,
      extensions: [c],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.teal,
        onPrimary: Colors.white,
        secondary: c.info,
        onSecondary: Colors.white,
        surface: c.card,
        onSurface: c.textPrimary,
        error: c.negative,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        TextTheme(
          displayLarge: TextStyle(color: c.textPrimary),
          displayMedium: TextStyle(color: c.textPrimary),
          displaySmall: TextStyle(color: c.textPrimary),
          headlineLarge: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: c.textSecondary),
          bodyMedium: TextStyle(color: c.textSecondary),
          bodySmall: TextStyle(color: c.textTertiary),
          labelLarge: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(color: c.textSecondary),
          labelSmall: TextStyle(color: c.textTertiary, letterSpacing: 0.8),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withAlpha(isDark ? 0 : 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark ? BorderSide(color: c.border) : BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: c.textPrimary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.card,
        selectedItemColor: c.teal,
        unselectedItemColor: c.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.teal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.negative, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.negative, width: 1),
        ),
        labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
        hintStyle: TextStyle(color: c.textTertiary, fontSize: 13),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.teal,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: c.textSecondary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? c.teal : c.textTertiary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? c.tealDim : c.surface),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.teal,
        inactiveTrackColor: c.surface,
        thumbColor: c.teal,
        overlayColor: c.tealDim,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.teal,
        linearTrackColor: c.surface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.elevated,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: c.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: c.border),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.teal,
        unselectedLabelColor: c.textTertiary,
        indicatorColor: c.teal,
        dividerColor: c.border,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.tealDim,
        labelStyle: TextStyle(color: c.textSecondary, fontSize: 12),
        side: BorderSide(color: c.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      useMaterial3: true,
    );
  }
}
