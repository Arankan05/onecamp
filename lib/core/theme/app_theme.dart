
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF7952B8);
  static const Color secondaryColor = Color(0xFFA987D8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ).copyWith(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: const Color(0xFFFFFFFF),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF302344),
      ),

      scaffoldBackgroundColor: const Color(0xFFF7F2FC),

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFFF7F2FC),
        foregroundColor: Color(0xFF302344),
      ),

      cardTheme: const CardThemeData(
        color: Color(0xFFFFFFFF),
        elevation: 2,
        surfaceTintColor: Colors.transparent,
      ),

      dividerColor: const Color(0xFFE9DDF8),

      floatingActionButtonTheme:
      const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: primaryColor,
        secondarySelectedColor: primaryColor,
        labelStyle: const TextStyle(
          color: Color(0xFF302344),
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
        ),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          color: Color(0xFF302344),
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF302344),
        ),
        titleLarge: TextStyle(
          color: Color(0xFF302344),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),

      scaffoldBackgroundColor: const Color(0xFF1D1727),

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1D1727),
        foregroundColor: Colors.white,
      ),
    );
  }
}
