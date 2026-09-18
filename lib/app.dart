import 'package:flutter/material.dart';

import 'domain/flag_catalog.dart';
import 'domain/flag_preferences.dart';
import 'domain/flag_preferences_store.dart';
import 'ui/home_screen.dart';
import 'ui/brand_theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'platform/flag_mode_platform.dart';

class AllFlagApp extends StatefulWidget {
  const AllFlagApp({
    super.key,
    required this.repository,
    required this.preferencesStore,
    this.flagModePlatform = const NativeFlagModePlatform(),
  });
  final FlagCatalog repository;
  final FlagPreferencesStore preferencesStore;
  final FlagModePlatform flagModePlatform;

  @override
  State<AllFlagApp> createState() => _AllFlagAppState();
}

class _AllFlagAppState extends State<AllFlagApp> {
  ThemePreference _theme = ThemePreference.system;
  LanguagePreference _language = LanguagePreference.system;

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
