import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/country.dart';
import '../domain/country_repository.dart';
import '../domain/flag.dart';

class LocalCountryRepository implements CountryRepository {
  const LocalCountryRepository();

  @override
  Future<List<Country>> loadCountries() async {
    final json = await rootBundle.loadString('assets/data/countries.json');
    final records = jsonDecode(json) as List<dynamic>;
    final countries =
        records.map((record) {
          final data = record as Map<String, dynamic>;
          final flag = data['flag'] as Map<String, dynamic>;
          return Country(
            code: data['code'] as String,
            name: data['name'] as String,
            flags: [
              Flag(
                id: flag['id'] as String,
                name: flag['name'] as String,
                asset: flag['asset'] as String,
                startYear: flag['startYear'] as int?,
              ),
            ],
          );
        }).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    return List.unmodifiable(countries);
  }
}
