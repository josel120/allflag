import 'package:allflag/data/country_flag_catalog.dart';

import 'support/flag_fixtures.dart';

import 'package:allflag/app.dart';
import 'package:allflag/data/local_country_repository.dart';
import 'package:allflag/data/shared_preferences_flag_store.dart';
import 'package:allflag/domain/country.dart';
import 'package:allflag/domain/flag_preferences.dart';
import 'package:allflag/platform/flag_mode_platform.dart';
import 'package:allflag/ui/flag_mode_controller.dart';
import 'package:allflag/ui/flag_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'country_preferences_test.dart' show MemoryStorage;
import 'support/memory_preferences_store.dart';
import 'support/recording_flag_mode_platform.dart';
import 'widget_test.dart' show SnapshotRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Country> catalog;
  setUpAll(
    () async => catalog = await const LocalCountryRepository().loadCountries(),
  );

  test(
    'zero or one Quick Flag; replacement/removal independent of favorites',
    () {
      var p = FlagPreferences();
      expect(p.quickFlag?.value, isNull);
      p = p.withQuickFlag(flagId('VE'));
      expect(p.quickFlag?.value, 'VE');
      expect(p.favorites.map((id) => id.value), isEmpty);
      expect(p.recent.map((id) => id.value), isEmpty);
      p = p
          .withQuickFlag(flagId('CA'))
          .toggleFavorite(flagId('CA'))
          .toggleFavorite(flagId('CA'));
      expect(p.quickFlag?.value, 'CA');
      expect(p.favorites.map((id) => id.value), isEmpty);
      p = p.toggleFavorite(flagId('JP')).withQuickFlag(null);
      expect(p.quickFlag?.value, isNull);
      expect(p.favorites.map((id) => id.value), {'JP'});
    },
  );

  test(
    'Quick Flag survives persisted language/theme changes and restart',
    () async {
      final disk = MemoryStorage();
      for (final language in LanguagePreference.values) {
        for (final theme in ThemePreference.values) {
          final p = FlagPreferences(quickFlag: flagId('DE'))
              .withLanguage(language)
              .withTheme(theme)
              .select(flagId('DE'))
              .select(flagId('DE'))
              .validFor({'DE'}.map(flagId).toSet());
          await SharedPreferencesFlagStore(storage: disk).save(p);
          final restored = await SharedPreferencesFlagStore(storage: disk)
              .load();
          expect(restored.quickFlag?.value, 'DE');
          expect(restored.language, language);
          expect(restored.theme, theme);
          expect(restored.recent.map((id) => id.value), ['DE']);
          expect(disk.values.values.single, isNot(contains('Germany')));
        }
      }
      await SharedPreferencesFlagStore(storage: disk).save(FlagPreferences());
      expect(
        (await SharedPreferencesFlagStore(storage: disk).load()).quickFlag,
        isNull,
      );
    },
  );

  test('old snapshots and malformed/stale ISO values are safe', () async {
    final disk = MemoryStorage();
    for (final json in [
      '{}',
      '{"quickFlag":4}',
      '{"quickFlag":"XX"}',
      '{"quickFlag":"Germany"}',
      '{"quickFlag":""}',
      '{"quickFlag":"de"}',
    ]) {
      disk.values[SharedPreferencesFlagStore.storageKey] = json;
      expect(
        (await SharedPreferencesFlagStore(
          storage: disk,
        ).load()).validFor({'DE'}.map(flagId).toSet()).quickFlag,
        isNull,
      );
    }
  });

  Future<void> start(
    WidgetTester tester,
    MemoryPreferencesStore store,
    RecordingFlagModePlatform platform,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      AllFlagApp(
        repository: CountryFlagCatalog(SnapshotRepository(catalog)),
        preferencesStore: store,
        flagModePlatform: platform,
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final code in [null, 'XX']) {
    testWidgets('card hidden for $code', (tester) async {
      await start(
        tester,
        MemoryPreferencesStore(
          FlagPreferences(quickFlag: code == null ? null : flagId(code)),
        ),
        RecordingFlagModePlatform(),
      );
      expect(find.byKey(const ValueKey('quick-flag-card')), findsNothing);
    });
  }

  testWidgets('assign, replace and remove through country actions', (
    tester,
  ) async {
    final store = MemoryPreferencesStore();
    await start(tester, store, RecordingFlagModePlatform());
    for (final entry in [('VE', 'Venezuela'), ('CA', 'Canada')]) {
      await tester.enterText(find.byType(TextField), entry.$1);
      await tester.pumpAndSettle();
      final row = find.byKey(ValueKey('country:${entry.$1}'));
      await tester.ensureVisible(row);
      await tester.tap(
        find.descendant(of: row, matching: find.byType(PopupMenuButton<bool>)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Set as Quick Flag'), findsOneWidget);
      await tester.tap(find.text('Set as Quick Flag'));
      await tester.pumpAndSettle();
      expect(store.value.quickFlag?.value, entry.$1);
      expect(store.value.favorites.map((id) => id.value), isEmpty);
      expect(store.value.recent.map((id) => id.value), isEmpty);
    }
    final card = find.byKey(const ValueKey('quick-flag-card'));
    await tester.ensureVisible(card);
    await tester.tap(
      find.descendant(of: card, matching: find.byType(PopupMenuButton<bool>)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove Quick Flag'));
    await tester.pumpAndSettle();
    expect(store.value.quickFlag?.value, isNull);
    expect(card, findsNothing);
  });

  testWidgets(
    'localized card and identity survive live language/theme changes',
    (tester) async {
      final store = MemoryPreferencesStore(
        FlagPreferences(quickFlag: flagId('DE')),
      );
      await start(tester, store, RecordingFlagModePlatform());
      expect(find.text('Quick Flag'), findsOneWidget);
      expect(find.text('Germany'), findsOneWidget);
      expect(find.text('Ready to display'), findsOneWidget);
      expect(find.text('Show flag'), findsOneWidget);
      await tester.tap(find.byTooltip('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();
      expect(find.text('Bandera rápida'), findsWidgets);
      expect(find.text('Alemania'), findsWidgets);
      expect(find.text('Lista para mostrar'), findsOneWidget);
      expect(find.text('Mostrar bandera'), findsOneWidget);
      await tester.tap(find.byTooltip('Tema'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();
      expect(store.value.quickFlag?.value, 'DE');
      expect(store.value.theme, ThemePreference.dark);
    },
  );

  for (final code in ['VE', 'US', 'CA', 'JP']) {
    testWidgets(
      '$code repeated Show flag, exit, Back and rotation restoration',
      (tester) async {
        final platform = RecordingFlagModePlatform();
        final store = MemoryPreferencesStore(
          FlagPreferences(quickFlag: flagId(code)),
        );
        await start(tester, store, platform);
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.text('Show flag'));
          await tester.pumpAndSettle();
          expect(
            tester.widget<FlagScreen>(find.byType(FlagScreen)).item.id.value,
            code,
          );
          expect(platform.landscapeRequested, isTrue);
          expect(platform.awake, isTrue);
          expect(platform.immersive, isTrue);
          expect(store.value.recent.map((id) => id.value), [code]);
          tester.view.physicalSize = const Size(900, 400);
          await tester.pumpAndSettle();
          if (i == 1) {
            await tester.binding.handlePopRoute();
          } else {
            await tester.tap(find.byTooltip('Exit Flag Mode'));
          }
          await tester.pumpAndSettle();
          expect(find.byType(FlagScreen), findsNothing);
          expect(platform.landscapeRequested, isFalse);
          expect(platform.awake, isFalse);
          expect(platform.immersive, isFalse);
          tester.view.physicalSize = const Size(400, 900);
          await tester.pumpAndSettle();
        }
        expect(store.value.quickFlag?.value, code);
      },
    );
  }

  testWidgets(
    'exit auto-hides, tapping reveals, background restores on resume',
    (tester) async {
      final platform = RecordingFlagModePlatform();
      await start(
        tester,
        MemoryPreferencesStore(FlagPreferences(quickFlag: flagId('JP'))),
        platform,
      );
      await tester.tap(find.text('Show flag'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      expect(find.byTooltip('Exit Flag Mode'), findsNothing);
      await tester.tap(find.byType(FlagScreen));
      await tester.pump();
      expect(find.byTooltip('Exit Flag Mode'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(platform.awake, isFalse);
      expect(platform.immersive, isFalse);
      expect(platform.landscapeRequested, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(platform.awake, isTrue);
      expect(platform.landscapeRequested, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(platform.awake, isFalse);
      expect(platform.landscapeRequested, isFalse);
    },
  );

  testWidgets('small screen and large text keep card actions reachable', (
    tester,
  ) async {
    await start(
      tester,
      MemoryPreferencesStore(
        FlagPreferences(
          quickFlag: flagId('US'),
          language: LanguagePreference.spanish,
          theme: ThemePreference.dark,
        ),
      ),
      RecordingFlagModePlatform(),
    );
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Mostrar bandera'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mostrar bandera'));
    await tester.pumpAndSettle();
    expect(find.byType(FlagScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Salir del modo bandera'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'screen reader retains accessible exit and meaningful Show label',
    (tester) async {
      final semantics = tester.ensureSemantics();

      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await start(
        tester,
        MemoryPreferencesStore(FlagPreferences(quickFlag: flagId('VE'))),
        RecordingFlagModePlatform(),
      );
      expect(find.bySemanticsLabel('Show Venezuela flag'), findsOneWidget);
      await tester.tap(find.text('Show flag'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      expect(find.byTooltip('Exit Flag Mode'), findsOneWidget);
      await tester.tap(find.byTooltip('Exit Flag Mode'));
      await tester.pumpAndSettle();
      semantics.dispose();
    },
  );
  test('public orientation API requests landscape then OS defaults', () async {
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    const platform = NativeFlagModePlatform();
    await platform.setLandscapeRequested(true);
    await platform.setLandscapeRequested(false);
    expect(
      calls.map((c) => c.method),
      everyElement('SystemChrome.setPreferredOrientations'),
    );
    expect(calls.first.arguments, [
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);
    expect(calls.last.arguments, isEmpty);
  });

  test(
    'coalesced programmatic entry and exit never leave orientation locked',
    () async {
      final platform = RecordingFlagModePlatform();
      final controller = FlagModeController(platform);
      controller.update(
        presenting: true,
        programmatic: true,
        lifecycle: AppLifecycleState.resumed,
      );
      controller.update(
        presenting: false,
        lifecycle: AppLifecycleState.resumed,
      );
      await controller.settled;
      expect(platform.landscapeRequested, isFalse);
      expect(platform.awake, isFalse);
      controller.dispose();
      await controller.settled;
    },
  );
}
