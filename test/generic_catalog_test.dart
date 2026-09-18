import 'dart:convert';

import 'package:allflag/app.dart';
import 'package:allflag/data/country_flag_catalog.dart';
import 'package:allflag/data/shared_preferences_flag_store.dart';
import 'package:allflag/domain/flag_catalog.dart';
import 'package:allflag/domain/flag_id.dart';
import 'package:allflag/domain/flag_item.dart';
import 'package:allflag/domain/flag_preferences.dart';
import 'package:allflag/l10n/flag_localization.dart';
import 'package:allflag/l10n/generated/app_localizations_es.dart';
import 'package:allflag/ui/flag_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'country_preferences_test.dart' show MemoryStorage;
import 'support/recording_flag_mode_platform.dart';

class StorageState {
  int writes = 0;
  bool fail = false;
}

class CountingStorage extends MemoryStorage {
  final state = StorageState();
  int get writes => state.writes;
  set fail(bool value) => state.fail = value;
  @override
  Future<void> setString(String key, String value) async {
    state.writes++;
    if (state.fail) throw StateError('Disk unavailable');
    await super.setString(key, value);
  }
}

class FixtureCatalog implements FlagCatalog {
  FixtureCatalog(this.items);
  final List<FlagItem> items;
  @override
  Future<List<FlagItem>> loadFlags() async => items;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlagId id(String value) => FlagId.tryParse(value)!;

  test('identity is namespaced, deterministic, strict and extensible', () {
    final first = id('fixture:example-1');
    expect(first, FlagId(FlagCategory('fixture'), 'example-1'));
    expect(first.hashCode, id(first.toString()).hashCode);
    expect(first, isNot(id('country:example-1')));
    for (final invalid in [
      '',
      'VE',
      ':VE',
      'country:',
      'Country:VE',
      'country:VE:extra',
      ' country:VE',
      'country:VE ',
      'country:../VE',
      'country:Perú',
      'country:VE\n',
    ]) {
      expect(FlagId.tryParse(invalid), isNull, reason: invalid);
    }
    expect(() => FlagCategory(''), throwsArgumentError);
    expect(() => FlagId(FlagCategory.country, ''), throwsArgumentError);
  });

  test(
    'production adapter preserves all countries and Spanish search',
    () async {
      final items = await const CountryFlagCatalog().loadFlags();
      expect(items, hasLength(195));
      expect(items.map((item) => item.id).toSet(), hasLength(195));
      expect(
        items.every((item) => item.category == FlagCategory.country),
        isTrue,
      );
      final peru = localizedFlags(
        items,
        AppLocalizationsEs(),
        query: '  pErU  ',
      );
      expect(peru.single.id, id('country:PE'));
      expect(peru.single.displayName('es'), 'Perú');
      expect(peru.single.asset, contains('pe'));
    },
  );

  test(
    'migration preserves order, settings and MRU; restart performs no write',
    () async {
      final disk = CountingStorage();
      disk.values[SharedPreferencesFlagStore.storageKey] = jsonEncode({
        'favorites': ['VE', 'country:VE', 'PE', 7, 'XX', 'JP'],
        'recent': [
          'XX',
          'VE',
          'country:VE',
          null,
          'PE',
          'JP',
          'US',
          'ES',
          'CA',
        ],
        'quickFlag': 'JP',
        'theme': 'dark',
        'language': 'spanish',
      });
      final available = [
        'VE',
        'PE',
        'JP',
        'US',
        'ES',
        'CA',
      ].map((code) => id('country:$code')).toSet();
      final p = await SharedPreferencesFlagStore(storage: disk)
          .load(availableIds: available);
      expect(p.favorites.map((id) => id.toString()), [
        'country:VE',
        'country:PE',
        'country:JP',
      ]);
      expect(p.recent.map((id) => id.toString()), [
        'country:VE',
        'country:PE',
        'country:JP',
        'country:US',
        'country:ES',
      ]);
      expect(p.quickFlag, id('country:JP'));
      expect(p.theme, ThemePreference.dark);
      expect(p.language, LanguagePreference.spanish);
      expect(disk.writes, 1);
      final serialized = disk.values.values.single;
      expect(jsonDecode(serialized)['schemaVersion'], 2);
      await SharedPreferencesFlagStore(storage: disk)
          .load(availableIds: available);
      expect(disk.writes, 1);
      expect(disk.values.values.single, serialized);
    },
  );

  test(
    'failed migration leaves old snapshot intact and retries safely',
    () async {
      final disk = CountingStorage()..fail = true;
      const original = '{"favorites":["VE"],"quickFlag":"VE"}';
      disk.values[SharedPreferencesFlagStore.storageKey] = original;
      final store = SharedPreferencesFlagStore(storage: disk);
      await expectLater(store.load(), throwsStateError);
      expect(disk.values.values.single, original);
      disk.fail = false;
      expect((await store.load()).quickFlag, id('country:VE'));
      await store.load();
      expect(disk.writes, 2);
    },
  );

  test(
    'v2 ignores raw ISO and stale IDs; unknown schemas are not overwritten',
    () async {
      final disk = CountingStorage();
      disk.values[SharedPreferencesFlagStore.storageKey] = jsonEncode({
        'schemaVersion': 2,
        'favorites': ['VE', 'fixture:one', 'fixture:one', 'fixture:missing'],
        'recent': ['fixture:missing', 'fixture:one'],
        'quickFlag': 'fixture:missing',
      });
      final p = await SharedPreferencesFlagStore(storage: disk)
          .load(availableIds: {id('fixture:one')});
      expect(p.favorites, {id('fixture:one')});
      expect(p.recent, [id('fixture:one')]);
      expect(p.quickFlag, isNull);
      disk.values[SharedPreferencesFlagStore.storageKey] =
          '{"schemaVersion":99}';
      await expectLater(
        SharedPreferencesFlagStore(storage: disk).load(),
        throwsFormatException,
      );
      expect(disk.values.values.single, '{"schemaVersion":99}');
    },
  );

  test(
    'generic preferences retain five unique MRU IDs across categories',
    () async {
      final ids = List.generate(7, (i) => id('fixture:item-$i'));
      var p = FlagPreferences(favorites: ids, quickFlag: ids.first);
      for (final item in ids) {
        p = p.select(item);
      }
      p = p.select(ids[3]).select(ids[3]).select(id('country:VE'));
      expect(p.recent, [id('country:VE'), ids[3], ids[6], ids[5], ids[4]]);
      final disk = MemoryStorage();
      await SharedPreferencesFlagStore(storage: disk).save(p);
      final restored = await SharedPreferencesFlagStore(storage: disk).load();
      expect(restored.recent, p.recent);
      expect(restored.favorites, p.favorites);
      expect(restored.quickFlag, p.quickFlag);
    },
  );

  testWidgets(
    'non-country item supports search, favorite, selection, Quick Flag and restart',
    (tester) async {
      // Synthetic category exists only in this test, reusing bundled test artwork.
      final item = FlagItem(
        id: id('fixture:sample'),
        asset: 'assets/flags/pe.png',
        defaultName: 'Sample',
        localizedNames: {'es': 'Ejémplo'},
        searchAliases: ['demo'],
      );
      final catalog = FixtureCatalog([item]);
      final disk = MemoryStorage();
      final platform = RecordingFlagModePlatform();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      Future<void> launch() async {
        await tester.pumpWidget(
          AllFlagApp(
            repository: catalog,
            preferencesStore: SharedPreferencesFlagStore(storage: disk),
            flagModePlatform: platform,
          ),
        );
        await tester.pumpAndSettle();
      }

      await launch();
      await tester.enterText(find.byType(TextField), '  DEMO ');
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('fixture:sample'));
      expect(row, findsOneWidget);
      await tester.tap(find.byTooltip('Add Sample to favorites'));
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(900, 400);
      await tester.pumpAndSettle();
      expect(
        tester.widget<FlagScreen>(find.byType(FlagScreen)).item.id,
        item.id,
      );
      expect(platform.awake, isTrue);
      tester.view.physicalSize = const Size(400, 900);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: row, matching: find.byType(PopupMenuButton<bool>)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set as Quick Flag'));
      await tester.pumpAndSettle();
      final saved = await SharedPreferencesFlagStore(storage: disk).load();
      expect(saved.favorites, {item.id});
      expect(saved.recent, [item.id]);
      expect(saved.quickFlag, item.id);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await launch();
      await tester.tap(find.text('Show flag'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FlagScreen>(find.byType(FlagScreen)).item.id,
        item.id,
      );
      expect(platform.landscapeRequested, isTrue);
      await tester.tap(find.byTooltip('Exit Flag Mode'));
      await tester.pumpAndSettle();
      expect(platform.awake, isFalse);
      expect((await SharedPreferencesFlagStore(storage: disk).load()).recent, [
        item.id,
      ]);
      expect(localizedFlags([item], AppLocalizationsEs(), query: 'ejemplo'), [
        item,
      ]);
      expect(tester.takeException(), isNull);
    },
  );
}
