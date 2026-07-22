import 'package:flutter/material.dart';

/// KidsBooks design system — warm, playful, storybook-like.
class KBColors {
  static const cream = Color(0xFFFFF8EF);
  static const coral = Color(0xFFFF6B57);
  static const teal = Color(0xFF2EC4B6);
  static const sunshine = Color(0xFFFFC94D);
  static const ink = Color(0xFF2D2A32);
  static const muted = Color(0xFF8B8496);

  /// Age band badge colors.
  static const age02 = Color(0xFFD9F7E8);
  static const age35 = Color(0xFFBFF0E4);
  static const age68 = Color(0xFFFFE3B3);
  static const age912 = Color(0xFFEBDFFF);
}

ThemeData buildKidsBooksTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: KBColors.coral,
      primary: KBColors.coral,
      secondary: KBColors.teal,
      surface: KBColors.cream,
    ),
    scaffoldBackgroundColor: KBColors.cream,
    fontFamily: 'Nunito',
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: KBColors.cream,
      foregroundColor: KBColors.ink,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: KBColors.coral,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      selectedColor: KBColors.teal,
    ),
  );
}
