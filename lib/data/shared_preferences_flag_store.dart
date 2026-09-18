import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/flag_id.dart';
import '../domain/flag_preferences.dart';
import '../domain/flag_preferences_store.dart';

/// Atomic snapshot; retain the historical key for in-place migration.
class SharedPreferencesFlagStore implements FlagPreferencesStore {
  SharedPreferencesFlagStore({SharedPreferencesAsync? storage})
    : _storage = storage ?? SharedPreferencesAsync();
  static const storageKey = 'allflag.country_preferences.v1';
  static const schemaVersion = 2;
  final SharedPreferencesAsync _storage;

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
    if (!legacy && version != schemaVersion) {
      throw const FormatException('Unsupported preferences schema');
    }
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
      theme: ThemePreference.values.firstWhere(
        (value) => value.name == decoded['theme'],
        orElse: () => ThemePreference.system,
      ),
    );
    final encoded = _encode(preferences);
    if (legacy || encoded != value) {
      await _storage.setString(storageKey, encoded);
    }
    return preferences;
  }

  String _encode(FlagPreferences preferences) => jsonEncode({
    'schemaVersion': schemaVersion,
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
