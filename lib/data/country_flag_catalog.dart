import '../domain/country.dart';
import '../domain/country_repository.dart';
import '../domain/flag_catalog.dart';
import '../domain/flag_id.dart';
import '../domain/flag_item.dart';
import '../l10n/generated/app_localizations_en.dart';
import '../l10n/generated/app_localizations_es.dart';
import 'local_country_repository.dart';

/// All ISO and country-name knowledge stops at this provider boundary.
class CountryFlagCatalog implements FlagCatalog {
  const CountryFlagCatalog([this.source = const LocalCountryRepository()]);
  final CountryRepository source;

  static FlagItem adapt(Country country) => FlagItem(
    id: FlagId(FlagCategory.country, country.code),
    asset: country.currentFlag.asset,
    defaultName: country.name,
    localizedNames: {
      'en': AppLocalizationsEn().countryName(country.code),
      'es': AppLocalizationsEs().countryName(country.code),
    },
    searchAliases: [country.code],
  );

  @override
  Future<List<FlagItem>> loadFlags() async =>
      List.unmodifiable((await source.loadCountries()).map(adapt));
}
