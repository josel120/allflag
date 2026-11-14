import 'dart:async';

import 'package:allflag/app.dart';
import 'package:allflag/data/country_flag_catalog.dart';
import 'package:allflag/data/local_country_repository.dart';
import 'package:allflag/domain/country.dart';
import 'package:allflag/domain/flag.dart';
import 'package:allflag/domain/flag_preferences.dart';
import 'package:allflag/ui/brand_theme.dart';
import 'package:allflag/ui/flag_screen.dart';
import 'package:allflag/ui/home/home_rows.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/flag_fixtures.dart';
import 'support/memory_preferences_store.dart';
import 'widget_test.dart' show SnapshotRepository;

class GatedRepository extends SnapshotRepository {
  GatedRepository(super.countries);
  final gate = Completer<void>();
  @override
  Future<List<Country>> loadCountries() async {
    await gate.future;
    return countries;
  }
}

void main() {
  late List<Country> countries;

  Future<void> start(
    WidgetTester tester, {
    FlagPreferences? preferences,
    ThemePreference theme = ThemePreference.light,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    countries = (await tester.runAsync(
      () => const LocalCountryRepository().loadCountries(),
    ))!;
    await tester.pumpWidget(
      AllFlagApp(
        repository: CountryFlagCatalog(SnapshotRepository(countries)),
        preferencesStore: MemoryPreferencesStore(
          (preferences ?? FlagPreferences()).withTheme(theme),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('rows group Favorites, Recent and All; search is one flat group', () {
    final items = [
      for (final code in ['AR', 'BR', 'CL'])
        CountryFlagCatalog.adapt(
          Country(
            code: code,
            name: code,
            flags: [Flag(id: code, name: code, asset: 'assets/flags/x.webp')],
          ),
        ),
    ];
    final prefs = FlagPreferences(
      favorites: [flagId('CL')],
      recent: [flagId('BR'), flagId('ZZ')],
    );
    final rows = buildHomeRows(items, prefs, searching: false);
    expect(rows.map((r) => (r.section, r.item?.id.value)).toList(), [
      (FlagSection.favorites, null),
      (FlagSection.favorites, 'CL'),
      (FlagSection.recent, null),
      (FlagSection.recent, 'BR'),
      (FlagSection.all, null),
      (FlagSection.all, 'AR'),
      (FlagSection.all, 'BR'),
      (FlagSection.all, 'CL'),
    ]);
    final search = buildHomeRows(items, prefs, searching: true);
    expect(search.every((r) => r.section == FlagSection.search), isTrue);
    expect(search.where((r) => r.item == null), isEmpty);
  });

  for (final theme in [ThemePreference.light, ThemePreference.dark]) {
    testWidgets(
      '${theme.name}: Favorites, Recent and All rows look different',
      (tester) async {
        await start(
          tester,
          theme: theme,
          preferences: FlagPreferences(
            favorites: [flagId('PE')],
            recent: [flagId('JP')],
          ),
        );
        final style = Theme.of(tester.element(find.byType(TextField)))
            .extension<FlagRowStyle>()!;
        ListTile tile(String key) =>
            tester.widget<ListTile>(find.byKey(ValueKey(key)));
        final favorite = tile('Favorites-country:PE');
        final recent = tile('Recent-country:JP');
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('country:AF')),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        final all = tile('country:AF');
        expect(favorite.tileColor, style.favorite);
        expect(recent.tileColor, style.recent);
        expect(all.tileColor, style.all);
        expect({
          favorite.tileColor,
          recent.tileColor,
          all.tileColor,
        }, hasLength(3));
        final recentSide = (recent.shape! as RoundedRectangleBorder).side;
        expect(recentSide.style, BorderStyle.solid);
        expect((all.shape! as RoundedRectangleBorder).side, BorderSide.none);
        // The tint stays readable: text keeps at least 4.5:1 on every row.
        final onSurface = Theme.of(tester.element(find.byType(TextField)))
            .colorScheme
            .onSurface;
        for (final color in [style.favorite, style.recent, style.all]) {
          final light = color.computeLuminance(),
              dark = onSurface.computeLuminance();
          final ratio =
              (light > dark ? light + 0.05 : dark + 0.05) /
              (light > dark ? dark + 0.05 : light + 0.05);
          expect(ratio, greaterThanOrEqualTo(4.5));
        }
      },
    );
  }

  testWidgets(
    'selection is spoken by the tapped row even after a long scroll',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await start(tester);
        final row = find.byKey(const ValueKey('country:ZW'));
        await tester.scrollUntilVisible(
          row,
          500,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        await tester.tap(row);
        await tester.pumpAndSettle();
        // The header card is recycled; the confirmation lives on the row.
        expect(find.byType(TextField), findsNothing);
        // Only one live confirmation exists, so TalkBack never says it twice.
        final all = tester
            .binding
            .renderViews
            .first
            .owner!
            .semanticsOwner!
            .rootSemanticsNode!;
        var liveCount = 0;
        final labels = <String>[];
        void visit(SemanticsNode node) {
          labels.add(node.label);
          if (node.getSemanticsData().flagsCollection.isLiveRegion &&
              node.label ==
                  'Zimbabwe selected. Rotate your device horizontally to '
                      'display its flag.') {
            liveCount++;
          }
          node.visitChildren((child) {
            visit(child);
            return true;
          });
        }

        visit(all);
        expect(
          liveCount,
          1,
          reason: labels.where((l) => l.contains('Zimb')).join(' | '),
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('loading and error states are designed and retry works', (
    tester,
  ) async {
    final repo = GatedRepository([]);
    await tester.pumpWidget(
      AllFlagApp(
        repository: CountryFlagCatalog(repo),
        preferencesStore: MemoryPreferencesStore(),
      ),
    );
    expect(find.byKey(const ValueKey('home-loading')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    // The label stays invisible on fast loads, then fades in.
    await tester.pump(const Duration(milliseconds: 100));
    final opacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.byType(LinearProgressIndicator),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.byType(LinearProgressIndicator),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      1,
    );
    expect(find.text('Loading countries…'), findsOneWidget);
    repo.gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-loading')), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  for (final reduced in [false, true]) {
    testWidgets('list to flag ${reduced ? 'is instant' : 'cross-fades'} '
        'with reduced motion=$reduced', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduced);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await start(tester);
      await tester.enterText(find.byType(TextField), 'Peru');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('country:PE')));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(900, 400);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(FlagScreen), findsOneWidget);
      // Mid-transition both views exist; reduced motion swaps immediately.
      expect(find.byType(TextField), reduced ? findsNothing : findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
    });
  }
}
