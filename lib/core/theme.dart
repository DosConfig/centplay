import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CentPlay Design System — based on supercent.io
/// Fonts: SBAggroOTF (headings) + Pretendard (body)
/// Colors: Deep black base + vivid purple (#E200FF) + electric blue (#4765FF)
/// Cards: rounded-[20px], dark, minimal

class AppTheme {
  static const _purple = Color(0xFFE200FF);
  static const _blue = Color(0xFF4765FF);
  static const _dark = Color(0xFF0A0A0A);

  // SBAggroOTF for display/headings
  static const _headingFont = 'SBAggroOTF';

  // Pretendard for body text (via Google Fonts)
  static TextTheme _bodyTextTheme([Brightness brightness = Brightness.light]) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    return GoogleFonts.notoSansKrTextTheme(base);
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final body = _bodyTextTheme(brightness);
    final headingColor =
        brightness == Brightness.dark ? Colors.white : _dark;

    return body.copyWith(
      displayLarge: TextStyle(
          fontFamily: _headingFont,
          fontWeight: FontWeight.w700,
          fontSize: 57,
          color: headingColor),
      displayMedium: TextStyle(
          fontFamily: _headingFont,
          fontWeight: FontWeight.w700,
          fontSize: 45,
          color: headingColor),
      displaySmall: TextStyle(
          fontFamily: _headingFont,
          fontWeight: FontWeight.w700,
          fontSize: 36,
          color: headingColor),
      headlineLarge: TextStyle(
          fontFamily: _headingFont,
          fontWeight: FontWeight.w700,
          fontSize: 32,
          color: headingColor,
          letterSpacing: -0.5),
      headlineMedium: TextStyle(
          fontFamily: _headingFont,
          fontWeight: FontWeight.w500,
          fontSize: 28,
          color: headingColor,
          letterSpacing: -0.3),
      headlineSmall: TextStyle(
          fontFamily: _headingFont,
          fontWeight: FontWeight.w500,
          fontSize: 24,
          color: headingColor,
          letterSpacing: -0.3),
      titleLarge: TextStyle(
          fontFamily: _headingFont,
          fontWeight: FontWeight.w500,
          fontSize: 20,
          color: headingColor,
          letterSpacing: -0.2),
    );
  }

  static ThemeData get light {
    final textTheme = _buildTextTheme(Brightness.light);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: _purple,
        secondary: _blue,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _dark,
        primaryContainer: _purple.withValues(alpha: 0.08),
        secondaryContainer: _blue.withValues(alpha: 0.08),
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: _dark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _headingFont,
          color: _dark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFAFAFA),
        surfaceTintColor: Colors.transparent,
        indicatorColor: _purple.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? _purple : Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.white : Colors.grey),
          side: WidgetStateProperty.all(BorderSide(color: Colors.grey.shade300)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        color: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _dark,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
              fontFamily: _headingFont,
              fontWeight: FontWeight.w500,
              fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _dark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: DividerThemeData(color: Colors.grey.shade200, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: _purple.withValues(alpha: 0.08),
        labelStyle: TextStyle(color: _purple, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
    );
  }

  static ThemeData get dark {
    final textTheme = _buildTextTheme(Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _dark,
      colorScheme: ColorScheme.dark(
        primary: _purple,
        secondary: _blue,
        surface: const Color(0xFF121212),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        primaryContainer: _purple.withValues(alpha: 0.15),
        secondaryContainer: _blue.withValues(alpha: 0.15),
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _dark,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _headingFont,
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF111111),
        surfaceTintColor: Colors.transparent,
        indicatorColor: _purple.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? _purple : Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.white : Colors.grey[600]),
          side: WidgetStateProperty.all(BorderSide(color: Colors.grey.shade700)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade800),
        ),
        color: const Color(0xFF1A1A1A),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
              fontFamily: _headingFont,
              fontWeight: FontWeight.w500,
              fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: Colors.grey.shade700),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: DividerThemeData(color: Colors.grey.shade800, space: 1),
    );
  }
}
