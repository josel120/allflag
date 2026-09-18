import 'dart:ui' as ui;

import 'package:allflag/data/local_country_repository.dart';
import 'package:allflag/domain/country.dart';
import 'package:allflag/domain/flag.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Flagpedia sovereign-state scope: 193 UN members plus PS and VA.
// Kept independent of the shipped JSON so omissions/substitutions fail tests.
const expectedCodes = '''
AD AE AF AG AL AM AO AR AT AU AZ BA BB BD BE BF BG BH BI BJ BN BO BR BS BT BW BY BZ
CA CD CF CG CH CI CL CM CN CO CR CU CV CY CZ DE DJ DK DM DO DZ EC EE EG ER ES ET
FI FJ FM FR GA GB GD GE GH GM GN GQ GR GT GW GY HN HR HT HU ID IE IL IN IQ IR IS IT
JM JO JP KE KG KH KI KM KN KP KR KW KZ LA LB LC LI LK LR LS LT LU LV LY
MA MC MD ME MG MH MK ML MM MN MR MT MU MV MW MX MY MZ NA NE NG NI NL NO NP NR NZ
OM PA PE PG PH PK PL PS PT PW PY QA RO RS RU RW SA SB SC SD SE SG SI SK SL SM SN
SO SR SS ST SV SY SZ TD TG TH TJ TL TM TN TO TR TT TV TZ UA UG US UY UZ VA VC VE VN
VU WS YE ZA ZM ZW
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const current = Flag(
    id: 'current',
    name: 'Current',
    asset: 'current.png',
    startYear: 2000,
  );
  const historical = Flag(
    id: 'old',
    name: 'Old',
    asset: 'old.png',
    startYear: 1900,
    endYear: 1999,
  );

  test('historical flags coexist with one current flag and are immutable', () {
    final input = [historical, current];
    final country = Country(code: 'XX', name: 'Example', flags: input);
    input.clear();
    expect(country.currentFlag, same(current));
    expect(country.flags.length, 2);
    expect(() => country.flags.clear(), throwsUnsupportedError);
  });

  test('countries reject missing or ambiguous current flags', () {
    for (final flags in <List<Flag>>[
      [],
      [historical],
      [current, current],
    ]) {
      expect(
        () => Country(code: 'XX', name: 'Example', flags: flags),
        throwsArgumentError,
      );
    }
  });

  test('unresearched adoption year stays unknown', () {
    const flag = Flag(id: 'unknown', name: 'Current', asset: 'unknown.png');
    expect(flag.startYear, isNull);
    expect(flag.endYear, isNull);
  });

  test(
    'catalog exactly covers 195 countries with unique codes and names',
    () async {
      final countries = await const LocalCountryRepository().loadCountries();
      final expected = expectedCodes.trim().split(RegExp(r'\s+')).toSet();
      expect(expected.length, 195);
      expect(countries.length, 195);
      expect(countries.map((c) => c.code).toSet(), expected);
      expect(countries.map((c) => c.name).toSet().length, 195);
      expect(countries.map((c) => c.currentFlag.id).toSet().length, 195);
      for (final country in countries) {
        expect(country.code, matches(RegExp(r'^[A-Z]{2}$')));
        expect(country.name.trim(), isNotEmpty);
        expect(country.flags.length, 1);
        expect(country.currentFlag.endYear, isNull);
      }
      expect(() => countries.clear(), throwsUnsupportedError);
    },
  );

  test(
    'countries are alphabetically ordered by English display name',
    () async {
      final countries = await const LocalCountryRepository().loadCountries();
      final names = countries.map((c) => c.name.toLowerCase()).toList();
      expect(names, orderedEquals([...names]..sort()));
      expect(countries.first.name, 'Afghanistan');
      expect(countries.last.name, 'Zimbabwe');
    },
  );

  test(
    'every local flag exists, decodes and retains native proportions',
    () async {
      final countries = await const LocalCountryRepository().loadCountries();
      for (final country in countries) {
        final data = await rootBundle.load(country.currentFlag.asset);
        final buffer = await ui.ImmutableBuffer.fromUint8List(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        expect(descriptor.width, 2560, reason: country.code);
        expect(descriptor.height, greaterThan(0), reason: country.code);
        final ratio = descriptor.width / descriptor.height;
        final expectedRatio = {
          'US': 1.9,
          'CH': 1.0,
          'JP': 1.5,
          'QA': 28 / 11,
        }[country.code];
        if (expectedRatio != null) {
          expect(ratio, closeTo(expectedRatio, 0.002), reason: country.code);
        }
        if (country.code == 'NP') {
          expect(
            ratio,
            lessThan(1),
            reason: 'Nepal must not become a rectangular landscape flag',
          );
        }
        final codec = await descriptor.instantiateCodec(targetWidth: 64);
        final frame = await codec.getNextFrame();
        frame.image.dispose();
        codec.dispose();
        descriptor.dispose();
        buffer.dispose();
      }
    },
  );
}
