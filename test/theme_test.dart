import 'package:allflag/data/country_flag_catalog.dart';

import 'support/flag_fixtures.dart';

import 'dart:async';
import 'dart:convert';

import 'package:allflag/app.dart';
import 'package:allflag/data/shared_preferences_flag_store.dart';
import 'package:allflag/domain/country.dart';
import 'package:allflag/domain/flag_id.dart';
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

class FailingLoadStore extends MemoryPreferencesStore {
  @override
  Future<FlagPreferences> load({Set<FlagId>? availableIds}) async =>
      throw StateError('Storage unavailable');
}

class CompleterStore extends MemoryPreferencesStore {
  CompleterStore(this.completer);
  final Completer<FlagPreferences> completer;
  @override
  Future<FlagPreferences> load({Set<FlagId>? availableIds}) => completer.future;
}

class NeverLoadsRepository extends SnapshotRepository {
  NeverLoadsRepository() : super([]);
  final gate = Completer<List<Country>>();
  @override
  Future<List<Country>> loadCountries() => gate.future;
}

Brightness textFieldBrightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(TextField))).brightness;

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
      // A light/dark choice saved by 1.0 survives even when it matches the OS.
      for (final os in Brightness.values) {
        final restored = await SharedPreferencesFlagStore(
          storage: disk,
          platformBrightness: () => os,
        ).load();
        expect(restored.theme, theme);
        expect(restored.favorites.map((id) => id.value), {'US', 'CA'});
        expect(restored.recent.map((id) => id.value), ['US', 'PE']);
      }
    });
  }

  group('0.9 frozen theme migration', () {
    for (final legacy in [
      '{"theme":"%s"}',
      '{"schemaVersion":2,"favorites":[],"recent":[],"theme":"%s"}',
    ]) {
      for (final saved in [ThemePreference.light, ThemePreference.dark]) {
        for (final os in Brightness.values) {
          final matches =
              (saved == ThemePreference.dark) == (os == Brightness.dark);
          test('${legacy.contains('schema') ? 'v2' : 'v1'} ${saved.name} '
              'with OS ${os.name} becomes '
              '${matches ? 'System' : saved.name}', () async {
            final disk = MemoryStorage();
            disk.values[SharedPreferencesFlagStore.storageKey] = legacy
                .replaceFirst('%s', saved.name);
            final store = SharedPreferencesFlagStore(
              storage: disk,
              platformBrightness: () => os,
            );
            final expected = matches ? ThemePreference.system : saved;
            expect((await store.load()).theme, expected);
            final written = jsonDecode(
              disk.values[SharedPreferencesFlagStore.storageKey]!,
            );
            expect(written['themeVersion'], 2);
            expect(written['schemaVersion'], 2);
            expect(written['theme'], expected.name);
            // Runs once: a later OS change never rewrites the choice.
            final flipped = SharedPreferencesFlagStore(
              storage: disk,
              platformBrightness: () =>
                  os == Brightness.dark ? Brightness.light : Brightness.dark,
            );
            expect((await flipped.load()).theme, expected);
          });
        }
      }
    }
  });

  test('initial preferences load before runApp and never block', () async {
    final store = MemoryPreferencesStore(
      FlagPreferences(theme: ThemePreference.dark),
    );
    expect((await loadInitialPreferences(store))?.theme, ThemePreference.dark);
    expect(await loadInitialPreferences(FailingLoadStore()), isNull);
    expect(
      await loadInitialPreferences(
        CompleterStore(Completer<FlagPreferences>()),
        timeout: const Duration(milliseconds: 10),
      ),
      isNull,
    );
  });

  for (final theme in [ThemePreference.light, ThemePreference.dark]) {
    testWidgets('saved ${theme.name} applies on the first frame', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue =
          theme == ThemePreference.dark ? Brightness.light : Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final repository = NeverLoadsRepository();
      await tester.pumpWidget(
        AllFlagApp(
          repository: CountryFlagCatalog(repository),
          preferencesStore: MemoryPreferencesStore(
            FlagPreferences(theme: theme),
          ),
          initialPreferences: FlagPreferences(theme: theme),
        ),
      );
      // Catalog still loading: no frame may show the opposite theme.
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        theme == ThemePreference.dark ? ThemeMode.dark : ThemeMode.light,
      );
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        theme == ThemePreference.dark ? Brightness.dark : Brightness.light,
      );
      repository.gate.complete([]);
      await tester.pumpAndSettle();
    });
  }

  for (final locale in ['en', 'es']) {
    testWidgets('$locale three-way theme menu with action semantics', (
      tester,
    ) async {
      final store = PendingStore();
      addTearDown(() {
        if (!store.gate.isCompleted) store.gate.complete();
      });
      tester.platformDispatcher.localesTestValue = [Locale(locale)];
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
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
        final names = locale == 'es'
            ? ['Sistema', 'Claro', 'Oscuro']
            : ['System', 'Light', 'Dark'];
        final prefix = locale == 'es' ? 'Tema' : 'Theme';
        final menu = find.byKey(const ValueKey('theme-menu'));
        final size = tester.getSize(menu);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
        // Fresh install: System, following the dark OS.
        expect(find.byTooltip('$prefix: ${names[0]}'), findsOneWidget);
        expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);
        expect(textFieldBrightness(tester), Brightness.dark);
        for (final (index, expected) in [
          (1, ThemeMode.light),
          (2, ThemeMode.dark),
          (0, ThemeMode.system),
          (1, ThemeMode.light),
        ]) {
          await tester.tap(menu);
          await tester.pumpAndSettle();
          expect(find.byType(PopupMenuItem<ThemePreference>), findsNWidgets(3));
          for (final name in names) {
            expect(find.text(name), findsOneWidget);
          }
          await tester.tap(find.text(names[index]));
          await tester.pump();
          expect(
            tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
            expected,
          );
          await tester.pumpAndSettle();
          expect(find.byTooltip('$prefix: ${names[index]}'), findsOneWidget);
          expect(
            textFieldBrightness(tester),
            expected == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        }
        // Writes queue behind the pending first save, then the latest wins.
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
      } finally {
        semantics.dispose();
      }
    });
  }

  for (final raw in <String?>[
    null,
    '{}',
    '{"theme":"system"}',
    '{"theme":"unknown"}',
    '{"theme":3}',
  ]) {
    testWidgets('System ($raw) follows live OS changes across restarts', (
      tester,
    ) async {
      final disk = MemoryStorage();
      if (raw != null) disk.values[SharedPreferencesFlagStore.storageKey] = raw;
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      Future<void> start() async {
        final store = SharedPreferencesFlagStore(storage: disk);
        await tester.pumpWidget(
          AllFlagApp(
            repository: CountryFlagCatalog(SnapshotRepository([])),
            preferencesStore: store,
            initialPreferences: await store.load(),
          ),
        );
        await tester.pumpAndSettle();
      }

      await start();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.system,
      );
      expect(textFieldBrightness(tester), Brightness.light);
      for (final os in [Brightness.dark, Brightness.light, Brightness.dark]) {
        tester.platformDispatcher.platformBrightnessTestValue = os;
        await tester.pumpAndSettle();
        expect(textFieldBrightness(tester), os);
      }
      // Never frozen into light/dark on disk.
      expect(
        (await SharedPreferencesFlagStore(storage: disk).load()).theme,
        ThemePreference.system,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await start();
      expect(textFieldBrightness(tester), Brightness.light);
    });
  }

  testWidgets('theme change animates, and is instant with reduced motion', (
    tester,
  ) async {
    Future<Duration> duration({required bool reduced}) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduced);
      await tester.pumpWidget(
        AllFlagApp(
          repository: CountryFlagCatalog(SnapshotRepository([])),
          preferencesStore: MemoryPreferencesStore(),
        ),
      );
      await tester.pumpAndSettle();
      return tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .themeAnimationDuration;
    }

    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    expect(await duration(reduced: false), greaterThan(Duration.zero));
    expect(await duration(reduced: true), Duration.zero);
  });

  for (final theme in ThemePreference.values) {
    testWidgets('${theme.name} chosen in the menu survives restart and '
        'rotation', (tester) async {
      final disk = MemoryStorage();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
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
      await tester.tap(find.byKey(const ValueKey('theme-menu')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(switch (theme) {
          ThemePreference.system => 'System',
          ThemePreference.light => 'Light',
          ThemePreference.dark => 'Dark',
        }),
      );
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferencesFlagStore(storage: disk).load()).theme,
        theme,
      );
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
