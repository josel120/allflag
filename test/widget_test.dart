import 'package:allflag/data/country_flag_catalog.dart';

import 'support/flag_fixtures.dart';

import 'dart:async';

import 'package:allflag/app.dart';
import 'package:allflag/data/local_country_repository.dart';
import 'package:allflag/domain/country.dart';
import 'package:allflag/domain/country_repository.dart';
import 'package:allflag/domain/flag_preferences.dart';
import 'package:allflag/domain/flag_preferences_store.dart';
import 'package:allflag/ui/flag_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_preferences_store.dart';

class SnapshotRepository implements CountryRepository {
  SnapshotRepository(this.countries);
  final List<Country> countries;
  @override
  Future<List<Country>> loadCountries() async => countries;
}

class RetryRepository extends SnapshotRepository {
  RetryRepository(super.countries);
  int calls = 0;
  @override
  Future<List<Country>> loadCountries() async {
    if (calls++ == 0) throw StateError('Offline');
    return countries;
  }
}

class DelayedPreferencesStore extends MemoryPreferencesStore {
  final gate = Completer<void>();
  int writes = 0;
  @override
  Future<void> save(FlagPreferences preferences) async {
    if (writes++ == 0) await gate.future;
    await super.save(preferences);
  }
}

void main() {
  Future<void> start(
    WidgetTester tester, {
    CountryRepository? repository,
    FlagPreferencesStore? preferencesStore,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Load the real bundled catalog outside the fake clock, since Flutter
    // decodes large asset strings on an isolate. UI receives all real records.
    final countries = await tester.runAsync(
      () => const LocalCountryRepository().loadCountries(),
    );
    await tester.pumpWidget(
      AllFlagApp(
        repository: CountryFlagCatalog(
          repository ?? SnapshotRepository(countries!),
        ),
        preferencesStore: preferencesStore ?? MemoryPreferencesStore(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('search filters by name/code, clears and handles no matches', (
    tester,
  ) async {
    await start(tester);
    expect(
      tester
          .widget<ListView>(find.byType(ListView))
          .childrenDelegate
          .estimatedChildCount,
      197,
    );
    expect(find.byType(ListTile).evaluate().length, lessThan(195));
    await tester.enterText(find.byType(TextField), '  pErU  ');
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('Peru'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Atlantis');
    await tester.pumpAndSettle();
    expect(find.textContaining('No countries found'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ListView>(find.byType(ListView))
          .childrenDelegate
          .estimatedChildCount,
      197,
    );
  });

  testWidgets(
    'rotation displays selected flag and preserves selection/search',
    (tester) async {
      final modes = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemChrome.setEnabledSystemUIMode') {
            modes.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await start(tester);
      await tester.enterText(find.byType(TextField), 'Peru');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Rotate your device horizontally'),
        findsOneWidget,
      );
      tester.view.physicalSize = const Size(900, 400);
      await tester.pumpAndSettle();
      expect(find.byType(FlagScreen), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain);
      expect((image.image as AssetImage).assetName, 'assets/flags/pe.png');
      expect(modes, contains('SystemUiMode.immersiveSticky'));
      tester.view.physicalSize = const Size(400, 900);
      await tester.pumpAndSettle();
      expect(find.byType(FlagScreen), findsNothing);
      expect(tester.widget<ListTile>(find.byType(ListTile)).selected, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Peru',
      );
      expect(modes.last, 'SystemUiMode.edgeToEdge');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('landscape without selection stays usable', (tester) async {
    await start(tester);
    tester.view.physicalSize = const Size(900, 400);
    await tester.pumpAndSettle();
    expect(find.byType(FlagScreen), findsNothing);
    await tester.enterText(find.byType(TextField), 'ven');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('country:VE')));
    await tester.tap(find.byKey(const ValueKey('country:VE')));
    await tester.pumpAndSettle();
    expect(find.byType(FlagScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed metadata load offers a working retry', (tester) async {
    final countries = await tester.runAsync(
      () => const LocalCountryRepository().loadCountries(),
    );
    await start(tester, repository: RetryRepository(countries!));
    expect(
      find.text('Could not load countries or saved choices.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ListView>(find.byType(ListView))
          .childrenDelegate
          .estimatedChildCount,
      197,
    );
  });

  testWidgets('partial search updates across the complete catalog', (
    tester,
  ) async {
    await start(tester);
    for (final entry in {
      'ven': ['Slovenia', 'Venezuela'],
      'JAP': ['Japan'],
      '  unit  ': ['United Arab Emirates', 'United Kingdom', 'United States'],
      'jp': ['Japan'],
      'zimb': ['Zimbabwe'],
    }.entries) {
      await tester.enterText(find.byType(TextField), entry.key);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ListView>(find.byType(ListView))
            .childrenDelegate
            .estimatedChildCount,
        entry.value.length + 1,
      );
      for (final name in entry.value) {
        expect(find.widgetWithText(ListTile, name), findsOneWidget);
      }
    }
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ListView>(find.byType(ListView))
          .childrenDelegate
          .estimatedChildCount,
      197,
    );
  });

  testWidgets('last country is reachable and remains selected after rotation', (
    tester,
  ) async {
    await start(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('country:ZW')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('country:ZW')));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(900, 400);
    await tester.pumpAndSettle();
    expect(
      tester.widget<FlagScreen>(find.byType(FlagScreen)).item.id.value,
      'ZW',
    );
    expect(find.byType(AppBar), findsNothing);
    tester.view.physicalSize = const Size(400, 900);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Zimbabwe');
    await tester.pumpAndSettle();
    expect(tester.widget<ListTile>(find.byType(ListTile)).selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty and stale shortcuts do not show headings', (tester) async {
    await start(
      tester,
      preferencesStore: MemoryPreferencesStore(
        FlagPreferences(
          favorites: ['XX'].map(flagId),
          recent: ['ZZ'].map(flagId),
        ),
      ),
    );
    expect(find.text('Favorites'), findsNothing);
    expect(find.text('Recent'), findsNothing);
    expect(find.text('All Countries'), findsOneWidget);
  });

  testWidgets('favorite control adds/removes without selecting the country', (
    tester,
  ) async {
    final store = MemoryPreferencesStore();
    await start(tester, preferencesStore: store);
    await tester.enterText(find.byType(TextField), 'Peru');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add Peru to favorites'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove Peru from favorites'), findsOneWidget);
    expect(find.textContaining('Peru selected.'), findsNothing);
    expect(store.value.favorites.map((id) => id.value), {'PE'});
    final semantics = tester.ensureSemantics();
    try {
      await tester.pump();
      expect(
        find.bySemanticsLabel('Remove Peru from favorites'),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.byKey(const ValueKey('Favorites-country:PE')), findsOneWidget);
    expect(find.text('Recent'), findsNothing);
    await tester.tap(find.byTooltip('Remove Peru from favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Favorites'), findsNothing);
    expect(store.value.favorites.map((id) => id.value), isEmpty);
  });

  testWidgets(
    'favorites and recents reload after app recreation and hide during search',
    (tester) async {
      final store = MemoryPreferencesStore();
      await start(tester, preferencesStore: store);
      await tester.enterText(find.byType(TextField), 'Peru');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add Peru to favorites'));
      await tester.tap(find.byKey(const ValueKey('country:PE')));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(900, 400);
      await tester.pumpAndSettle();
      expect(find.byType(FlagScreen), findsOneWidget);
      tester.view.physicalSize = const Size(400, 900);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove Peru from favorites'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await start(tester, preferencesStore: store);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Recent'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('Favorites-country:PE')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('Recent-country:PE')), findsOneWidget);
      await tester.enterText(find.byType(TextField), '  pER  ');
      await tester.pumpAndSettle();
      expect(find.text('Favorites'), findsNothing);
      expect(find.text('Recent'), findsNothing);
      expect(find.text('All Countries'), findsNothing);
      expect(find.byKey(const ValueKey('country:PE')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('country:PE')));
      await tester.pumpAndSettle();
      expect(store.value.recent.map((id) => id.value), ['PE']);
    },
  );

  testWidgets(
    'selection updates and persists five recents in most recent order',
    (tester) async {
      final store = MemoryPreferencesStore();
      await start(tester, preferencesStore: store);
      for (final name in [
        'Peru',
        'Japan',
        'Spain',
        'United States',
        'Afghanistan',
        'Zimbabwe',
        'Japan',
      ]) {
        await tester.enterText(find.byType(TextField), name);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ListTile));
        await tester.pumpAndSettle();
      }
      expect(store.value.recent.map((id) => id.value), [
        'JP',
        'ZW',
        'AF',
        'US',
        'ES',
      ]);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Recent'), findsOneWidget);
      final visibleRecents = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .where(
            (tile) =>
                (tile.key! as ValueKey<String>).value.startsWith('Recent-'),
          )
          .map((tile) => (tile.title! as Text).data)
          .toList();
      expect(visibleRecents, [
        'Japan',
        'Zimbabwe',
        'Afghanistan',
        'United States',
        'Spain',
      ]);
    },
  );

  testWidgets('save failure is visible and retry persists latest choices', (
    tester,
  ) async {
    final store = MemoryPreferencesStore()..failWrites = true;
    await start(tester, preferencesStore: store);
    await tester.enterText(find.byType(TextField), 'Peru');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add Peru to favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save your choices. Retry'), findsOneWidget);
    store.failWrites = false;
    await tester.tap(find.text('Could not save your choices. Retry'));
    await tester.pumpAndSettle();
    expect(store.value.favorites.map((id) => id.value), {'PE'});
    expect(find.text('Could not save your choices. Retry'), findsNothing);
  });

  testWidgets('rapid toggles persist in order even after screen disposal', (
    tester,
  ) async {
    final store = DelayedPreferencesStore();
    await start(tester, preferencesStore: store);
    await tester.enterText(find.byType(TextField), 'Peru');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add Peru to favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove Peru from favorites'));
    await tester.pumpAndSettle();
    expect(store.writes, 1);
    await tester.pumpWidget(const SizedBox());
    store.gate.complete();
    await tester.pumpAndSettle();
    expect(store.writes, 2);
    expect(store.value.favorites.map((id) => id.value), isEmpty);
    expect(tester.takeException(), isNull);
  });
}
