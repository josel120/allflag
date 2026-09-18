import 'support/flag_fixtures.dart';

import 'package:allflag/domain/flag_preferences.dart';
import 'package:allflag/data/shared_preferences_flag_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

// Fake only the platform API; production JSON encoding/decoding is exercised.
class MemoryStorage implements SharedPreferencesAsync {
  final values = <String, String>{};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('favorites add, remove, deduplicate and preserve recent', () {
    var choices = FlagPreferences(
      favorites: ['PE', 'PE'].map(flagId),
      recent: ['JP'].map(flagId),
    );
    expect(choices.favorites.map((id) => id.value), {'PE'});
    choices = choices.toggleFavorite(flagId('VE'));
    expect(choices.favorites.map((id) => id.value), {'PE', 'VE'});
    choices = choices.toggleFavorite(flagId('PE'));
    expect(choices.favorites.map((id) => id.value), {'VE'});
    expect(choices.recent.map((id) => id.value), ['JP']);
  });

  test(
    'recent is most recent first, capped at five and moves an existing code',
    () {
      var choices = FlagPreferences(favorites: ['PE'].map(flagId));
      for (final code in ['PE', 'JP', 'VE', 'US', 'ES', 'AF']) {
        choices = choices.select(flagId(code));
      }
      expect(choices.recent.map((id) => id.value), [
        'AF',
        'ES',
        'US',
        'VE',
        'JP',
      ]);
      choices = choices.select(flagId('VE')).select(flagId('VE'));
      expect(choices.recent.map((id) => id.value), [
        'VE',
        'AF',
        'ES',
        'US',
        'JP',
      ]);
      expect(choices.favorites.map((id) => id.value), {'PE'});
    },
  );

  test(
    'stale persisted codes are ignored without changing valid recent order',
    () {
      final choices = FlagPreferences(
        favorites: ['XX', 'PE', 'PE'].map(flagId),
        recent: ['XX', 'JP', 'JP', 'PE', ''].map(flagId),
      ).validFor({'PE', 'JP'}.map(flagId).toSet());
      expect(choices.favorites.map((id) => id.value), {'PE'});
      expect(choices.recent.map((id) => id.value), ['JP', 'PE']);
    },
  );

  test(
    'favorites and recents persist across storage adapter instances',
    () async {
      final disk = MemoryStorage();
      final first = SharedPreferencesFlagStore(storage: disk);
      await first.save(
        FlagPreferences(
          favorites: ['PE', 'JP'].map(flagId),
          recent: ['VE', 'PE'].map(flagId),
        ),
      );
      final restarted = SharedPreferencesFlagStore(storage: disk);
      final choices = await restarted.load();
      expect(choices.favorites.map((id) => id.value), {'PE', 'JP'});
      expect(choices.recent.map((id) => id.value), ['VE', 'PE']);
      await restarted.save(
        choices.toggleFavorite(flagId('PE')).select(flagId('JP')),
      );
      final again = await SharedPreferencesFlagStore(storage: disk).load();
      expect(again.favorites.map((id) => id.value), {'JP'});
      expect(again.recent.map((id) => id.value), ['JP', 'VE', 'PE']);
      expect(disk.values.values.single, isNot(contains('Peru')));
      expect(disk.values.values.single, isNot(contains('assets/')));
    },
  );

  test('absent, malformed and wrong-shape storage is safe', () async {
    final disk = MemoryStorage();
    final store = SharedPreferencesFlagStore(storage: disk);
    expect((await store.load()).favorites.map((id) => id.value), isEmpty);
    for (final value in [
      'not json',
      '[]',
      'null',
      '{"favorites":1,"recent":false}',
    ]) {
      disk.values[SharedPreferencesFlagStore.storageKey] = value;
      final choices = await store.load();
      expect(choices.favorites.map((id) => id.value), isEmpty);
      expect(choices.recent.map((id) => id.value), isEmpty);
    }
  });

  test('mixed persisted values and duplicates are filtered', () async {
    final disk = MemoryStorage();
    disk.values[SharedPreferencesFlagStore.storageKey] =
        '{"favorites":["PE",3,"PE",null],"recent":["JP","JP",false,"PE"]}';
    final choices = await SharedPreferencesFlagStore(storage: disk).load();
    expect(choices.favorites.map((id) => id.value), {'PE'});
    expect(choices.recent.map((id) => id.value), ['JP', 'PE']);
  });
}
