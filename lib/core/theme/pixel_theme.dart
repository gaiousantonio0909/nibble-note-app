import 'package:flutter/material.dart';

/// Cute-but-minimal pixel palette used across the whole app.
///
/// The colors are picked to look OK together on both light and dark
/// backgrounds and to keep the pet's default costume readable at small sizes.
class NibblePalette {
  const NibblePalette._();

  static const Color background = Color(0xFFFBF3E4); // warm cream
  static const Color surface = Color(0xFFFFFAF0);
  static const Color primary = Color(0xFFE97DA1); // strawberry pink
  static const Color primaryDark = Color(0xFFB94E7A);
  static const Color accent = Color(0xFF7ED6A5); // mint (used sparingly)
  static const Color petBody = Color(0xFFFFC98A); // toasty orange
  static const Color petShade = Color(0xFFE39456);
  static const Color petBelly = Color(0xFFFFE7C2);
  static const Color petEye = Color(0xFF2E2A2A);
  static const Color petBlush = Color(0xFFFFA9A9);
  static const Color costumeHat = Color(0xFFE94F5C); // little chef hat / bow
  static const Color ink = Color(0xFF3C2E2A);
  static const Color inkSoft = Color(0xFF7A5D57);
}

ThemeData buildNibbleTheme() {
  const base = ColorScheme(
    brightness: Brightness.light,
    primary: NibblePalette.primary,
    onPrimary: Colors.white,
    secondary: NibblePalette.accent,
    onSecondary: NibblePalette.ink,
    surface: NibblePalette.surface,
    onSurface: NibblePalette.ink,
    error: Color(0xFFB3261E),
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    scaffoldBackgroundColor: NibblePalette.background,
    fontFamily: 'monospace', // pixel-y feel without shipping a custom font
    appBarTheme: const AppBarTheme(
      backgroundColor: NibblePalette.background,
      foregroundColor: NibblePalette.ink,
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NibblePalette.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: NibblePalette.ink, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: NibblePalette.ink, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: NibblePalette.primary, width: 3),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NibblePalette.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: NibblePalette.ink, width: 2),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: NibblePalette.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: NibblePalette.ink, width: 2),
      ),
    ),
  );
}
