import 'flag_id.dart';

/// Only information needed to find and display artwork. Native image dimensions
/// determine proportions, including square and nonrectangular artwork.
final class FlagItem {
  FlagItem({
    required this.id,
    required this.asset,
    required this.defaultName,
    Map<String, String> localizedNames = const {},
    Iterable<String> searchAliases = const [],
  }) : _localizedNames = Map.unmodifiable(localizedNames),
       searchAliases = List.unmodifiable(searchAliases);

  final FlagId id;
  FlagCategory get category => id.category;
  final String asset;
  final String defaultName;
  final Map<String, String> _localizedNames;
  final List<String> searchAliases;

  String displayName(String languageCode) =>
      _localizedNames[languageCode] ?? defaultName;
}
