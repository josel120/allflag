import 'package:allflag/data/country_flag_catalog.dart';

import 'support/flag_fixtures.dart';

import 'dart:async';

import 'package:allflag/app.dart';
import 'package:allflag/data/shared_preferences_flag_store.dart';
import 'package:allflag/domain/flag_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'country_preferences_test.dart' show MemoryStorage;
import 'support/memory_preferences_store.dart';
import 'widget_test.dart' show SnapshotRepository;

class PendingStore extends MemoryPreferencesStore {
  final gate = Completer<void>();
  @override
  Future<void> save(FlagPreferences preferences) async {
    await gate.future;
    await super.save(preferences);
  }
}

void main() {
  test('old and unknown theme values default to System', () async {
    final disk = MemoryStorage();
    final store = SharedPreferencesFlagStore(storage: disk);
    expect((await store.load()).theme, ThemePreference.system);
    for (final json in [
      '{"favorites":["US"]}',
      '{"theme":"unknown"}',
      '{"theme":3}',
    ]) {
      disk.values[SharedPreferencesFlagStore.storageKey] = json;
      expect((await store.load()).theme, ThemePreference.system);
    }
  });

  for (final theme in ThemePreference.values) {
    test('persists ${theme.name} and preserves other choices', () async {
      final disk = MemoryStorage();
      final choices =
          FlagPreferences(
                favorites: ['US'].map(flagId),
                recent: ['PE'].map(flagId),
              )
              .withTheme(theme)
              .toggleFavorite(flagId('CA'))
              .select(flagId('US'))
              .validFor({'US', 'CA', 'PE'}.map(flagId).toSet());
      await SharedPreferencesFlagStore(storage: disk).save(choices);
      final restored = await SharedPreferencesFlagStore(storage: disk).load();
      expect(restored.theme, theme);
      expect(restored.favorites.map((id) => id.value), {'US', 'CA'});
      expect(restored.recent.map((id) => id.value), ['US', 'PE']);
    });
  }

  testWidgets(
    'System default, Light, Dark, System apply immediately and follow OS',
    (tester) async {
      final store = PendingStore();
      addTearDown(() {
        if (!store.gate.isCompleted) store.gate.complete();
      });
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(
        AllFlagApp(
          repository: CountryFlagCatalog(SnapshotRepository([])),
          preferencesStore: store,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.system,
      );
      expect(
        Theme.of(tester.element(find.byType(TextField))).brightness,
        Brightness.dark,
      );
      for (final entry in [
        ('Light', ThemeMode.light, Brightness.light),
        ('Dark', ThemeMode.dark, Brightness.dark),
        ('System', ThemeMode.system, Brightness.dark),
      ]) {
        await tester.tap(find.byTooltip('Theme'));
        await tester.pumpAndSettle();
        expect(find.byType(PopupMenuItem<ThemePreference>), findsNWidgets(3));
        expect(find.byIcon(Icons.check), findsOneWidget);
        await tester.tap(find.text(entry.$1));
        await tester.pumpAndSettle();
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
          entry.$2,
        );
        expect(
          Theme.of(tester.element(find.byType(TextField))).brightness,
          entry.$3,
        );
      }
      // All changes are visible even while the first disk write is pending.
      expect(store.gate.isCompleted, isFalse);
      store.gate.complete();
      await tester.pumpAndSettle();
      expect(store.value.theme, ThemePreference.system);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(TextField))).brightness,
        Brightness.light,
      );
    },
  );

  for (final theme in ThemePreference.values) {
    testWidgets('${theme.name} survives app recreation and rotation', (
      tester,
    ) async {
      final disk = MemoryStorage();
      Future<void> start() async {
        await tester.pumpWidget(
          AllFlagApp(
            repository: CountryFlagCatalog(SnapshotRepository([])),
            preferencesStore: SharedPreferencesFlagStore(storage: disk),
          ),
        );
        await tester.pumpAndSettle();
      }

      await start();
      await tester.tap(find.byTooltip('Theme'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(switch (theme) {
          ThemePreference.system => 'System',
          ThemePreference.light => 'Light',
          ThemePreference.dark => 'Dark',
        }),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await start();
      final expected = switch (theme) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      };
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        expected,
      );
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final size in [const Size(900, 400), const Size(400, 900)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
          expected,
        );
        expect(tester.takeException(), isNull);
      }
    });
  }
}
