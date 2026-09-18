import 'package:flutter/material.dart';

/// AllFlag's neutral interface lets the national flags provide the color.
abstract final class BrandTokens {
  static const navy = Color(0xFF101C30);
  static const blue = Color(0xFF2364D8);
  static const cyan = Color(0xFF42C9E8);
  static const orange = Color(0xFFFFAD66);
  static const pink = Color(0xFFEF718C);
  static const lightBackground = Color(0xFFF7F8FA);
  static const lightSurface = Color(0xFFEEF1F5);
  static const darkBackground = Color(0xFF0E1624);
  static const darkSurface = Color(0xFF1A2638);
  static const radius = 16.0;
  static const pagePadding = 20.0;
  static const touchTarget = 48.0;

  static ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: blue, brightness: brightness)
        .copyWith(
          primary: dark ? const Color(0xFF91B9FF) : blue,
          onPrimary: dark ? navy : Colors.white,
          surface: dark ? darkBackground : lightBackground,
          surfaceContainerLow: dark ? darkSurface : lightSurface,
          onSurface: dark ? const Color(0xFFEAF0F8) : navy,
          onSurfaceVariant: dark
              ? const Color(0xFFAFBDD0)
              : const Color(0xFF526176),
          primaryContainer: dark
              ? const Color(0xFF233C60)
              : const Color(0xFFE2ECFC),
          onPrimaryContainer: dark
              ? const Color(0xFFDCE9FF)
              : const Color(0xFF173F7B),
        );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: shape,
        minTileHeight: 68,
        minLeadingWidth: 48,
        horizontalTitleGap: 12,
        tileColor: scheme.surfaceContainerLow,
        selectedTileColor: scheme.primaryContainer,
        selectedColor: scheme.onPrimaryContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        titleTextStyle: base.textTheme.titleMedium!.copyWith(
          color: scheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(touchTarget, touchTarget),
          foregroundColor: scheme.onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.primaryContainer,
        shape: shape,
      ),
    );
  }
}
