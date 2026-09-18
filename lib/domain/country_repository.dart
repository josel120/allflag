import 'country.dart';

/// Asynchronous boundary for local or future remote metadata.
abstract interface class CountryRepository {
  Future<List<Country>> loadCountries();
}
