import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: FSColors.background,
        colorScheme: const ColorScheme.dark(
          primary: FSColors.teal,
          secondary: FSColors.info,
          surface: FSColors.card,
          error: FSColors.negative,
          onPrimary: Color(0xFF0F1117),
          onSecondary: FSColors.textPrimary,
          onSurface: FSColors.textPrimary,
          onError: FSColors.textPrimary,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          const TextTheme(
            displayLarge:  TextStyle(color: FSColors.textPrimary),
            displayMedium: TextStyle(color: FSColors.textPrimary),
            displaySmall:  TextStyle(color: FSColors.textPrimary),
            headlineLarge: TextStyle(color: FSColors.textPrimary, fontWeight: FontWeight.w700),
            headlineMedium:TextStyle(color: FSColors.textPrimary, fontWeight: FontWeight.w600),
            headlineSmall: TextStyle(color: FSColors.textPrimary, fontWeight: FontWeight.w600),
            titleLarge:    TextStyle(color: FSColors.textPrimary, fontWeight: FontWeight.w600),
            titleMedium:   TextStyle(color: FSColors.textPrimary, fontWeight: FontWeight.w500),
            titleSmall:    TextStyle(color: FSColors.textPrimary, fontWeight: FontWeight.w500),
            bodyLarge:     TextStyle(color: FSColors.textSecondary),
            bodyMedium:    TextStyle(color: FSColors.textSecondary),
            bodySmall:     TextStyle(color: FSColors.textTertiary),
            labelLarge:    TextStyle(color: FSColors.textPrimary, fontWeight: FontWeight.w600),
            labelMedium:   TextStyle(color: FSColors.textSecondary),
            labelSmall:    TextStyle(color: FSColors.textTertiary, letterSpacing: 0.8),
          ),
        ),
        cardTheme: CardThemeData(
          color: FSColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: FSColors.border),
          ),
          margin: EdgeInsets.zero,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: FSColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: FSColors.textPrimary),
          titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: FSColors.textPrimary,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: FSColors.card,
          selectedItemColor: FSColors.teal,
          unselectedItemColor: FSColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 10),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: FSColors.tertiary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: FSColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: FSColors.teal, width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: FSColors.negative, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: FSColors.negative, width: 1),
          ),
          labelStyle: const TextStyle(color: FSColors.textSecondary, fontSize: 13),
          hintStyle: const TextStyle(color: FSColors.textTertiary, fontSize: 13),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: FSColors.teal,
          foregroundColor: Color(0xFF0F1117),
          elevation: 4,
        ),
        dividerTheme: const DividerThemeData(
          color: FSColors.border,
          thickness: 1,
          space: 1,
        ),
        iconTheme: const IconThemeData(color: FSColors.textSecondary),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? FSColors.teal : FSColors.textTertiary),
          trackColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? FSColors.tealDim : FSColors.tertiary),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: FSColors.teal,
          inactiveTrackColor: FSColors.tertiary,
          thumbColor: FSColors.teal,
          overlayColor: Color(0x1F3ECFB2),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: FSColors.teal,
          linearTrackColor: FSColors.tertiary,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: FSColors.card,
          contentTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: FSColors.textPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: FSColors.border),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: FSColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: FSColors.teal,
          unselectedLabelColor: FSColors.textTertiary,
          indicatorColor: FSColors.teal,
          dividerColor: FSColors.border,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: FSColors.tertiary,
          selectedColor: FSColors.tealDim,
          labelStyle: const TextStyle(color: FSColors.textSecondary, fontSize: 12),
          side: const BorderSide(color: FSColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        useMaterial3: true,
      );
}
