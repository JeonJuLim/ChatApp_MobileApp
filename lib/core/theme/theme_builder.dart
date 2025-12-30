import 'package:flutter/material.dart';
import 'app_appearance.dart';

class ThemeBuilder {
  static ColorScheme _schemeFor(AppPalette palette, {required bool dark}) {
    switch (palette) {
      case AppPalette.purple:
        return dark
            ? const ColorScheme.dark(
          primary: Color(0xFF7C3AED),
          secondary: Color(0xFF4C1D95),
        )
            : const ColorScheme.light(
          primary: Color(0xFF7C3AED),
          secondary: Color(0xFF4C1D95),
        );

      case AppPalette.blue:
        return dark
            ? const ColorScheme.dark(
          primary: Color(0xFF0EA5E9),
          secondary: Color(0xFF0369A1),
        )
            : const ColorScheme.light(
          primary: Color(0xFF0EA5E9),
          secondary: Color(0xFF0369A1),
        );

      case AppPalette.pastel:
      default:
      // pastel (default)
        return dark
            ? const ColorScheme.dark(
          primary: Color(0xFF7C3AED),
          secondary: Color(0xFF22C55E),
        )
            : const ColorScheme.light(
          primary: Color(0xFF7C3AED),
          secondary: Color(0xFF22C55E),
        );
    }
  }

  static double textScale(FontScale scale) {
    switch (scale) {
      case FontScale.small:
        return 0.92;
      case FontScale.large:
        return 1.10;
      case FontScale.medium:
      default:
        return 1.0;
    }
  }

  static ThemeData light(AppAppearance a) {
    final scheme = _schemeFor(a.palette, dark: false);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF7F7FB),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      listTileTheme: const ListTileThemeData(iconColor: Colors.black87),
    );
  }

  static ThemeData dark(AppAppearance a) {
    final scheme = _schemeFor(a.palette, dark: true);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF020617),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    );
  }
}
