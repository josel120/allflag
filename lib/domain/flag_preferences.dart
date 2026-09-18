import 'flag_id.dart';

enum ThemePreference { system, light, dark }

enum LanguagePreference { system, english, spanish }

/// Small immutable snapshot of locally persisted user choices.
class FlagPreferences {
  FlagPreferences({
    Iterable<FlagId> favorites = const [],
    Iterable<FlagId> recent = const [],
    this.theme = ThemePreference.system,
    this.language = LanguagePreference.system,
    this.quickFlag,
  }) : favorites = Set.unmodifiable(favorites),
       recent = List.unmodifiable(recent.toSet().take(5));

  final Set<FlagId> favorites;
  final List<FlagId> recent;
  final ThemePreference theme;
  final LanguagePreference language;
  final FlagId? quickFlag;

  FlagPreferences withQuickFlag(FlagId? id) => FlagPreferences(
    favorites: favorites,
    recent: recent,
    theme: theme,
    language: language,
    quickFlag: id,
  );

  FlagPreferences withLanguage(LanguagePreference value) => FlagPreferences(
    favorites: favorites,
    recent: recent,
    theme: theme,
    language: value,
    quickFlag: quickFlag,
  );

  FlagPreferences withTheme(ThemePreference value) => FlagPreferences(
    favorites: favorites,
    recent: recent,
    theme: value,
    quickFlag: quickFlag,
    language: language,
  );

  FlagPreferences validFor(Set<FlagId> ids) => FlagPreferences(
    favorites: favorites.where(ids.contains),
    recent: recent.where(ids.contains),
    quickFlag: ids.contains(quickFlag) ? quickFlag : null,
    theme: theme,
    language: language,
  );

  FlagPreferences toggleFavorite(FlagId id) => FlagPreferences(
    favorites: favorites.contains(id)
        ? favorites.where((item) => item != id)
        : [...favorites, id],
    quickFlag: quickFlag,
    recent: recent,
    theme: theme,
    language: language,
  );

  FlagPreferences select(FlagId id) => FlagPreferences(
    favorites: favorites,
    recent: [id, ...recent.where((item) => item != id)],
    quickFlag: quickFlag,
    theme: theme,
    language: language,
  );
}
