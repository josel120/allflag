import 'package:flutter/material.dart';

/// Motion budget: only whole-view changes animate (list ↔ flag, theme, search
/// results). Rows never animate. Every duration honors "Remove animations".
abstract final class AllFlagMotion {
  static const quick = Duration(milliseconds: 150);
  static const reveal = Duration(milliseconds: 220);
  static const standard = Duration(milliseconds: 300);
  static const curve = Curves.easeOutCubic;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ??
      WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .disableAnimations;

  static Duration duration(BuildContext context, Duration value) =>
      reduced(context) ? Duration.zero : value;
}

/// Section-specific row surfaces, so Favorites, Recent and All Countries read
/// as different groups without relying on the star icon alone.
@immutable
class FlagRowStyle extends ThemeExtension<FlagRowStyle> {
  const FlagRowStyle({
    required this.favorite,
    required this.recent,
    required this.recentBorder,
    required this.all,
  });

  /// Light primary tint; full primaryContainer stays reserved for selection.
  final Color favorite;

  /// Quiet outlined row: recent history, not a saved choice.
  final Color recent;
  final Color recentBorder;

  /// Neutral filled row for the full catalog and search results.
  final Color all;

  factory FlagRowStyle.of(ColorScheme scheme) => FlagRowStyle(
    favorite: Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.10),
      scheme.surfaceContainerLow,
    ),
    recent: scheme.surface,
    recentBorder: scheme.outlineVariant,
    all: scheme.surfaceContainerLow,
  );

  @override
  FlagRowStyle copyWith({
    Color? favorite,
    Color? recent,
    Color? recentBorder,
    Color? all,
  }) => FlagRowStyle(
    favorite: favorite ?? this.favorite,
    recent: recent ?? this.recent,
    recentBorder: recentBorder ?? this.recentBorder,
    all: all ?? this.all,
  );

  @override
  FlagRowStyle lerp(FlagRowStyle? other, double t) => other == null
      ? this
      : FlagRowStyle(
          favorite: Color.lerp(favorite, other.favorite, t)!,
          recent: Color.lerp(recent, other.recent, t)!,
          recentBorder: Color.lerp(recentBorder, other.recentBorder, t)!,
          all: Color.lerp(all, other.all, t)!,
        );
}

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
  static const listTileHorizontalPadding = 16.0;
  static const touchTarget = 48.0;

  /// The only raised surface: Quick Flag is the screen's primary action.
  static const quickCardElevation = 1.0;

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
    // System font (Roboto/SF) keeps full glyph coverage for localized names;
    // hierarchy comes from weight, tracking and line height.
    final text = base.textTheme;
    final textTheme = text.copyWith(
      headlineMedium: text.headlineMedium!.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      titleMedium: text.titleMedium!.copyWith(fontWeight: FontWeight.w600),
      titleSmall: text.titleSmall!.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: scheme.onSurfaceVariant,
      ),
      bodyLarge: text.bodyLarge!.copyWith(height: 1.4),
      bodyMedium: text.bodyMedium!.copyWith(height: 1.4),
      bodySmall: text.bodySmall!.copyWith(
        height: 1.4,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: text.labelLarge!.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );
    final dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius + 8),
    );
    return base.copyWith(
      textTheme: textTheme,
      extensions: [FlagRowStyle.of(scheme)],
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
        subtitleTextStyle: textTheme.bodySmall,
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
        shadowColor: scheme.shadow,
        surfaceTintColor: Colors.transparent,
        shape: shape,
      ),
      // Defined now so future screens never reintroduce loose colors.
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: shape,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
      dialogTheme: DialogThemeData(shape: dialogShape),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerLow,
      ),
    );
  }
}
