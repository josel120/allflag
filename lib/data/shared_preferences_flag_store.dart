import 'dart:convert';
import 'dart:ui' show Brightness, PlatformDispatcher;

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/flag_id.dart';
import '../domain/flag_preferences.dart';
import '../domain/flag_preferences_store.dart';

/// Atomic snapshot; retain the historical key for in-place migration.
class SharedPreferencesFlagStore implements FlagPreferencesStore {
  SharedPreferencesFlagStore({
    SharedPreferencesAsync? storage,
    Brightness Function()? platformBrightness,
  }) : _storage = storage ?? SharedPreferencesAsync(),
       _platformBrightness =
           platformBrightness ??
           (() => PlatformDispatcher.instance.platformBrightness);
  static const storageKey = 'allflag.country_preferences.v1';
  static const schemaVersion = 2;

  /// Up to 0.9, "system" was resolved once to light/dark and frozen. Version 2
  /// marks snapshots where "system" is a real choice that follows the OS. It is
  /// a separate key so older builds can still read the schema after a downgrade.
  static const themeVersion = 2;
  final SharedPreferencesAsync _storage;
  final Brightness Function() _platformBrightness;

  @override
  Future<FlagPreferences> load({Set<FlagId>? availableIds}) async {
    final value = await _storage.getString(storageKey);
    if (value == null) return FlagPreferences();
    dynamic decoded;
    try {
      decoded = jsonDecode(value);
    } on FormatException {
      return FlagPreferences();
    }
    if (decoded is! Map<String, dynamic>) return FlagPreferences();
    final version = decoded['schemaVersion'];
    final legacy = version == null || version == 1;
    // A newer build wrote this snapshot (downgrade): start from defaults
    // without overwriting it, so upgrading again restores the user's choices.
    if (!legacy && version != schemaVersion) return FlagPreferences();
    FlagId? parse(dynamic raw) {
      if (raw is! String) return null;
      final id = legacy && RegExp(r'^[A-Z]{2}$').hasMatch(raw)
          ? FlagId(FlagCategory.country, raw)
          : FlagId.tryParse(raw);
      return id != null && (availableIds == null || availableIds.contains(id))
          ? id
          : null;
    }

    Iterable<FlagId> ids(dynamic raw) =>
        raw is List ? raw.map(parse).whereType<FlagId>() : const <FlagId>[];
    // Filter stale entries before imposing the five-item MRU limit.
    final preferences = FlagPreferences(
      favorites: ids(decoded['favorites']),
      recent: ids(decoded['recent']),
      quickFlag: parse(decoded['quickFlag']),
      language: LanguagePreference.values.firstWhere(
        (value) => value.name == decoded['language'],
        orElse: () => LanguagePreference.system,
      ),
      theme: _migrateTheme(
        ThemePreference.values.firstWhere(
          (value) => value.name == decoded['theme'],
          orElse: () => ThemePreference.system,
        ),
        frozen: decoded['themeVersion'] != themeVersion,
      ),
    );
    final encoded = _encode(preferences);
    if (legacy || encoded != value) {
      await _storage.setString(storageKey, encoded);
    }
    return preferences;
  }

  /// A frozen light/dark value that still matches the OS is indistinguishable
  /// from the old automatic resolution: it becomes System, which looks the same
  /// today and follows the OS from now on. A value that differs from the OS was
  /// most likely chosen on purpose and is kept.
  ThemePreference _migrateTheme(ThemePreference theme, {required bool frozen}) {
    if (!frozen || theme == ThemePreference.system) return theme;
    final systemDark = _platformBrightness() == Brightness.dark;
    return (theme == ThemePreference.dark) == systemDark
        ? ThemePreference.system
        : theme;
  }

  String _encode(FlagPreferences preferences) => jsonEncode({
    'schemaVersion': schemaVersion,
    'themeVersion': themeVersion,
    'favorites': preferences.favorites.map((id) => id.toString()).toList(),
    'recent': preferences.recent.map((id) => id.toString()).toList(),
    'quickFlag': preferences.quickFlag?.toString(),
    'theme': preferences.theme.name,
    'language': preferences.language.name,
  });

  @override
  Future<void> save(FlagPreferences preferences) =>
      _storage.setString(storageKey, _encode(preferences));
}
