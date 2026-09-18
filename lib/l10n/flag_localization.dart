import '../domain/flag_item.dart';
import 'generated/app_localizations.dart';

/// Matching only: displayed names always retain their original Unicode spelling.
String normalizeSearch(String value) {
  const accents = 'áàâäãåéèêëíìîïóòôöõúùûüñç';
  const plain = 'aaaaaaeeeeiiiiooooouuuunc';
  final lower = value.toLowerCase();
  final folded = String.fromCharCodes(
    lower.runes.map((rune) {
      final index = accents.indexOf(String.fromCharCode(rune));
      return index < 0 ? rune : plain.codeUnitAt(index);
    }),
  );
  return folded
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

String _sortKey(String value, String locale) {
  // Spanish treats ñ as a distinct letter after n; other accents use base letters.
  if (locale == 'es') {
    value = value
        .toLowerCase()
        .replaceAll('n\u0303', 'ñ')
        .replaceAll('ñ', 'n\uffff');
  }
  return normalizeSearch(value);
}

List<FlagItem> localizedFlags(
  Iterable<FlagItem> items,
  AppLocalizations l10n, {
  String query = '',
}) {
  final normalized = normalizeSearch(query);
  final matches = <({FlagItem item, String sortKey})>[];
  for (final item in items) {
    final name = item.displayName(l10n.localeName);
    if (normalizeSearch(name).contains(normalized) ||
        item.searchAliases.any(
          (alias) => normalizeSearch(alias).contains(normalized),
        )) {
      matches.add((item: item, sortKey: _sortKey(name, l10n.localeName)));
    }
  }
  matches.sort((a, b) {
    final comparison = a.sortKey.compareTo(b.sortKey);
    return comparison == 0
        ? a.item.id.toString().compareTo(b.item.id.toString())
        : comparison;
  });
  return matches.map((match) => match.item).toList();
}
