import '../../domain/flag_item.dart';
import '../../domain/flag_preferences.dart';

/// Groups on Home. Each one has its own row surface (see FlagRowStyle).
enum FlagSection { favorites, recent, all, search }

/// A section heading (item == null) or a country row.
typedef HomeRow = ({FlagSection section, FlagItem? item});

/// [sorted] is already filtered and localized. Without a query, rows are
/// Favorites, Recent (most recent first) and All Countries; empty sections and
/// stale IDs produce no heading.
List<HomeRow> buildHomeRows(
  List<FlagItem> sorted,
  FlagPreferences preferences, {
  required bool searching,
}) {
  if (searching) {
    return [
      for (final item in sorted) (section: FlagSection.search, item: item),
    ];
  }
  final rows = <HomeRow>[];
  void section(FlagSection section, Iterable<FlagItem> values) {
    final list = values.toList();
    if (list.isEmpty) return;
    rows.add((section: section, item: null));
    rows.addAll(list.map((item) => (section: section, item: item)));
  }

  section(
    FlagSection.favorites,
    sorted.where((item) => preferences.favorites.contains(item.id)),
  );
  final byId = {for (final item in sorted) item.id: item};
  section(
    FlagSection.recent,
    preferences.recent.map((id) => byId[id]).whereType<FlagItem>(),
  );
  section(FlagSection.all, sorted);
  return rows;
}
