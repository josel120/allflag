import 'package:flutter/material.dart';

import 'domain/flag_catalog.dart';
import 'domain/flag_preferences.dart';
import 'domain/flag_preferences_store.dart';
import 'ui/home_screen.dart';
import 'ui/brand_theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'platform/flag_mode_platform.dart';

/// Reads saved choices before the first frame so the app opens directly in the
/// saved theme and language. Never blocks startup on storage problems: the home
/// screen loads again and shows its own error and retry.
Future<FlagPreferences?> loadInitialPreferences(
  FlagPreferencesStore store, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  try {
    return await store.load().timeout(timeout);
  } catch (_) {
    return null;
  }
}

class AllFlagApp extends StatefulWidget {
  const AllFlagApp({
    super.key,
    required this.repository,
    required this.preferencesStore,
    this.initialPreferences,
    this.flagModePlatform = const NativeFlagModePlatform(),
  });
  final FlagCatalog repository;
  final FlagPreferencesStore preferencesStore;

  /// Saved choices read before `runApp`; null falls back to System.
  final FlagPreferences? initialPreferences;
  final FlagModePlatform flagModePlatform;

  @override
  State<AllFlagApp> createState() => _AllFlagAppState();
}

class _AllFlagAppState extends State<AllFlagApp> {
  late ThemePreference _theme =
      widget.initialPreferences?.theme ?? ThemePreference.system;
  late LanguagePreference _language =
      widget.initialPreferences?.language ?? LanguagePreference.system;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AllFlag',
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: switch (_language) {
      LanguagePreference.system => null,
      LanguagePreference.english => const Locale('en'),
      LanguagePreference.spanish => const Locale('es'),
    },
    localeListResolutionCallback: (locales, supported) =>
        Locale(locales?.firstOrNull?.languageCode == 'es' ? 'es' : 'en'),
    debugShowCheckedModeBanner: false,
    theme: BrandTokens.theme(Brightness.light),
    darkTheme: BrandTokens.theme(Brightness.dark),
    themeMode: switch (_theme) {
      ThemePreference.system => ThemeMode.system,
      ThemePreference.light => ThemeMode.light,
      ThemePreference.dark => ThemeMode.dark,
    },
    themeAnimationDuration: AllFlagMotion.duration(
      context,
      AllFlagMotion.quick,
    ),
    themeAnimationCurve: AllFlagMotion.curve,
    home: HomeScreen(
      repository: widget.repository,
      preferencesStore: widget.preferencesStore,
      flagModePlatform: widget.flagModePlatform,
      onLanguageChanged: (language) {
        if (mounted && _language != language) {
          setState(() => _language = language);
        }
      },
      onThemeChanged: (theme) {
        if (mounted && _theme != theme) setState(() => _theme = theme);
      },
    ),
  );
}
