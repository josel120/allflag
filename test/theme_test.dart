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

  for (final locale in ['en', 'es']) {
    testWidgets(
      '$locale direct toggle, action semantics and immediate updates',
      (tester) async {
        final store = PendingStore();
        addTearDown(() {
          if (!store.gate.isCompleted) store.gate.complete();
        });
        tester.platformDispatcher.localesTestValue = [Locale(locale)];
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            AllFlagApp(
              repository: CountryFlagCatalog(SnapshotRepository([])),
              preferencesStore: store,
            ),
          );
          await tester.pumpAndSettle();
          for (var tap = 0; tap < 6; tap++) {
            final dark = tap.isOdd;
            final label = locale == 'es'
                ? (dark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro')
                : (dark ? 'Switch to light mode' : 'Switch to dark mode');
            expect(find.byTooltip(label), findsOneWidget);
            expect(find.bySemanticsLabel(label), findsOneWidget);
            expect(
              find.byIcon(
                dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
              findsOneWidget,
            );
            final size = tester.getSize(
              find.byKey(const ValueKey('appearance-toggle')),
            );
            expect(size.width, greaterThanOrEqualTo(48));
            expect(size.height, greaterThanOrEqualTo(48));
            expect(find.byType(PopupMenuButton<ThemePreference>), findsNothing);
            await tester.tap(find.byTooltip(label));
            await tester.pump();
            expect(
              tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
              dark ? ThemeMode.light : ThemeMode.dark,
            );
            await tester.pumpAndSettle();
            expect(
              Theme.of(tester.element(find.byType(TextField))).brightness,
              dark ? Brightness.light : Brightness.dark,
            );
            expect(find.byType(PopupMenuItem<ThemePreference>), findsNothing);
          }
          expect(store.gate.isCompleted, isFalse);
          store.gate.complete();
          await tester.pumpAndSettle();
          expect(store.value.theme, ThemePreference.light);
          await tester.tap(find.byIcon(Icons.language));
          await tester.pumpAndSettle();
          expect(
            find.byType(PopupMenuItem<LanguagePreference>),
            findsNWidgets(2),
          );
          expect(find.text('English'), findsOneWidget);
          expect(find.text('Español'), findsOneWidget);
          expect(find.text('System'), findsNothing);
          expect(find.text('Sistema'), findsNothing);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  for (final brightness in Brightness.values) {
    for (final raw in <String?>[
      null,
      '{}',
      '{"theme":"system"}',
      '{"theme":"unknown"}',
      '{"theme":3}',
    ]) {
      testWidgets('$brightness migrates $raw once and survives restart', (
        tester,
      ) async {
        final disk = MemoryStorage();
        if (raw != null) {
          disk.values[SharedPreferencesFlagStore.storageKey] = raw;
        }
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
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
        final expected = brightness == Brightness.dark
            ? ThemePreference.dark
            : ThemePreference.light;
        expect(
          (await SharedPreferencesFlagStore(storage: disk).load()).theme,
          expected,
        );
        tester.platformDispatcher.platformBrightnessTestValue =
            brightness == Brightness.dark ? Brightness.light : Brightness.dark;
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(TextField))).brightness,
          brightness,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await start();
        expect(
          Theme.of(tester.element(find.byType(TextField))).brightness,
          brightness,
        );
      });
    }
  }

  for (final theme in [ThemePreference.light, ThemePreference.dark]) {
    testWidgets('${theme.name} selected by tap survives restart and rotation', (
      tester,
    ) async {
      final disk = MemoryStorage();
      await SharedPreferencesFlagStore(storage: disk).save(
        FlagPreferences(
          theme: theme == ThemePreference.light
              ? ThemePreference.dark
              : ThemePreference.light,
          language: LanguagePreference.english,
        ),
      );
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
      await tester.tap(find.byKey(const ValueKey('appearance-toggle')));
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferencesFlagStore(storage: disk).load()).theme,
        theme,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await start();
      final expected = theme == ThemePreference.light
          ? ThemeMode.light
          : ThemeMode.dark;
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
