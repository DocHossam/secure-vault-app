import 'package:flutter/material.dart';

class VaultTheme {
  static const Color primary = Color(0xFF34D399);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF6EE7B7);
  static const Color accent = Color(0xFF67E8F9);
  static const Color background = Color(0xFF080D16);
  static const Color surface = Color(0xFF111A29);
  static const Color surfaceLight = Color(0xFF192538);
  static const Color border = Color(0xFF263449);
  static const Color textPrimary = Color(0xFFF4F7FB);
  static const Color textSecondary = Color(0xFF9AAAC0);
  static const Color textMuted = Color(0xFF64748B);
  static const Color error = Color(0xFFF87171);
  static const Color warning = Color(0xFFFBBF24);
  static const Color info = Color(0xFF60A5FA);

  static const List<List<Color>> cardGradients = [
    [Color(0xFF1E293B), Color(0xFF0F172A)],
    [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    [Color(0xFF059669), Color(0xFF047857)],
    [Color(0xFF0284C7), Color(0xFF0369A1)],
    [Color(0xFFB45309), Color(0xFF78350F)],
    [Color(0xFFBE123C), Color(0xFF881337)],
  ];

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(primary: primary, secondary: accent, surface: surface, error: error, onPrimary: Color(0xFF06251D), onSurface: textPrimary),
    appBarTheme: const AppBarTheme(backgroundColor: background, elevation: 0, scrolledUnderElevation: 0, centerTitle: false, titleTextStyle: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -.5), iconTheme: IconThemeData(color: textPrimary)),
    cardTheme: CardThemeData(color: surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: border))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: surfaceLight, contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16), hintStyle: const TextStyle(color: textMuted, fontSize: 13), labelStyle: const TextStyle(color: textSecondary, fontSize: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primary, width: 1.5)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: error))),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: const Color(0xFF06251D), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
    floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: primary, foregroundColor: const Color(0xFF06251D), elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26)))),
    snackBarTheme: SnackBarThemeData(backgroundColor: surfaceLight, contentTextStyle: const TextStyle(color: textPrimary, fontWeight: FontWeight.w500), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: border)), behavior: SnackBarBehavior.floating),
  );
}
