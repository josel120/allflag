import 'package:allflag/data/country_flag_catalog.dart';

import 'support/flag_fixtures.dart';

import 'dart:convert';
import 'dart:io';

import 'package:allflag/app.dart';
import 'package:allflag/data/local_country_repository.dart';
import 'package:allflag/data/shared_preferences_flag_store.dart';
import 'package:allflag/domain/country.dart';
import 'package:allflag/domain/flag_preferences.dart';
import 'package:allflag/domain/flag_preferences_store.dart';
import 'package:allflag/l10n/flag_localization.dart';
import 'package:allflag/l10n/generated/app_localizations.dart';
import 'package:allflag/l10n/generated/app_localizations_en.dart';
import 'package:allflag/l10n/generated/app_localizations_es.dart';
import 'package:allflag/ui/flag_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'country_preferences_test.dart' show MemoryStorage;
import 'domain_test.dart' show expectedCodes;
import 'support/memory_preferences_store.dart';
import 'theme_test.dart' show PendingStore;
import 'widget_test.dart' show SnapshotRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Country> catalog;
  final en = AppLocalizationsEn();
  final es = AppLocalizationsEs();
  setUpAll(() async {
    catalog = await const LocalCountryRepository().loadCountries();
  });

  Future<void> launch(
    WidgetTester tester, {
    FlagPreferencesStore? store,
    Locale locale = const Locale('en'),
    Size size = const Size(400, 900),
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.localesTestValue = [locale];
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      AllFlagApp(
        repository: CountryFlagCatalog(SnapshotRepository(catalog)),
        preferencesStore: store ?? MemoryPreferencesStore(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> language(WidgetTester tester, String option) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<LanguagePreference>), findsNWidgets(2));
    await tester.tap(find.text(option));
    await tester.pumpAndSettle();
  }

  String activeLocale(WidgetTester tester) =>
      Localizations.localeOf(tester.element(find.byType(TextField)))
          .languageCode;

  test(
    'all 195 ISO identities have complete English and Spanish ARB names',
    () {
      final expected = expectedCodes.trim().split(RegExp(r'\s+')).toSet();
      expect(catalog.length, 195);
      expect(catalog.map((c) => c.code).toSet(), expected);
      expect(AppLocalizations.supportedLocales, [
        const Locale('en'),
        const Locale('es'),
      ]);
      for (final l10n in [en, es]) {
        final arb = jsonDecode(
          File('lib/l10n/app_${l10n.localeName}.arb').readAsStringSync(),
        ) as Map<String, dynamic>;
        final codes = RegExp(r'\b([A-Z]{2})\{')
            .allMatches(arb['countryName'] as String)
            .map((match) => match[1])
            .toList();
        expect(codes.length, 195);
        expect(codes.toSet(), expected);
        expect(
          catalog.map((c) => l10n.countryName(c.code)).toSet().length,
          195,
        );
        for (final country in catalog) {
          expect(l10n.countryName(country.code), isNotEmpty);
          expect(l10n.countryName(country.code), isNot(l10n.countryName('XX')));
          if (l10n == en) expect(l10n.countryName(country.code), country.name);
        }
      }
      expect(es.countryName('DE'), 'Alemania');
      expect(es.countryName('US'), 'Estados Unidos');
      expect(es.countryName('JP'), 'Japón');
      expect(es.countryName('CI'), 'Costa de Marfil');
    },
  );

  test('every application message exists in both ARB resources', () {
    Set<String> keys(String locale) =>
        (jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
                as Map<String, dynamic>)
            .keys
            .where((key) => !key.startsWith('@'))
            .toSet();
    expect(keys('es'), keys('en'));
    expect(en.appName, 'AllFlag');
    expect(es.appName, 'AllFlag');
  });

  for (final l10n in [en, es]) {
    test('${l10n.localeName} sorts all displayed names alphabetically', () {
      final countries = localizedFlags(
        catalog.reversed.map(CountryFlagCatalog.adapt),
        l10n,
      );
      // Independent accent folding for the current 195-name catalog.
      String key(Country c) => l10n
          .countryName(c.code)
          .toLowerCase()
          .replaceAll('á', 'a')
          .replaceAll('é', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ú', 'u')
          .replaceAll('ñ', 'n\uffff');
      final expected = [...catalog]..sort((a, b) => key(a).compareTo(key(b)));
      expect(countries.map((c) => c.id.value), expected.map((c) => c.code));
      if (l10n == es) {
        expect(countries.take(4).map((c) => c.id.value), [
          'AF',
          'AL',
          'DE',
          'AD',
        ]);
        expect(
          countries.indexWhere((c) => c.id.value == 'ES'),
          lessThan(countries.indexWhere((c) => c.id.value == 'EE')),
        );
      }
    });
  }

  final searches = <(String, String, List<String>)>[
    ('en', 'germ', ['DE']),
    ('en', 'jap', ['JP']),
    ('en', 'unit', ['AE', 'GB', 'US']),
    ('en', '  GeRM  ', ['DE']),
    ('es', 'alem', ['DE']),
    ('es', 'jap', ['JP']),
    ('es', 'estados', ['US']),
    ('es', 'peru', ['PE']),
    ('es', 'PerÚ', ['PE']),
    ('es', '  PeRu  ', ['PE']),
    ('es', 'mexico', ['MX']),
    ('es', 'panama', ['PA']),
    ('es', 'PERU\u0301', ['PE']),
    ('es', ' emiratos   árabes\t unidos ', ['AE']),
    ('es', '  jp ', ['JP']),
  ];
  for (final (locale, query, expected) in searches) {
    test('$locale partial normalized search: $query', () {
      expect(
        localizedFlags(
          catalog.map(CountryFlagCatalog.adapt),
          locale == 'es' ? es : en,
          query: query,
        ).map((c) => c.id.value).toSet(),
        expected.toSet(),
      );
    });
  }
  test('search uses active language and keeps display accents', () {
    expect(
      localizedFlags(
        catalog.map(CountryFlagCatalog.adapt),
        es,
        query: 'germany',
      ),
      isEmpty,
    );
    expect(
      localizedFlags(
        catalog.map(CountryFlagCatalog.adapt),
        en,
        query: 'alemania',
      ),
      isEmpty,
    );
    expect(es.countryName('PE'), 'Perú');
    expect(es.countryName('MX'), 'México');
    expect(es.countryName('PA'), 'Panamá');
    expect(normalizeSearch('  \t '), '');
  });

  test(
    'legacy, missing and unknown language preferences default to System',
    () async {
      final disk = MemoryStorage();
      final store = SharedPreferencesFlagStore(storage: disk);
      expect((await store.load()).language, LanguagePreference.system);
      for (final json in [
        '{"favorites":["DE"],"recent":["PE"],"theme":"dark"}',
        '{"language":"unknown"}',
        '{"language":42}',
      ]) {
        disk.values[SharedPreferencesFlagStore.storageKey] = json;
        expect((await store.load()).language, LanguagePreference.system);
      }
    },
  );

  for (final preference in LanguagePreference.values) {
    test(
      '${preference.name} persistence preserves independent theme and ISO data',
      () async {
        final disk = MemoryStorage();
        var choices = FlagPreferences(
          favorites: ['DE'].map(flagId),
          recent: ['PE'].map(flagId),
          theme: ThemePreference.dark,
        ).withLanguage(preference);
        choices = choices
            .toggleFavorite(flagId('US'))
            .select(flagId('JP'))
            .validFor({'DE', 'US', 'PE', 'JP'}.map(flagId).toSet())
            .withTheme(ThemePreference.light);
        await SharedPreferencesFlagStore(storage: disk).save(choices);
        final restored = await SharedPreferencesFlagStore(storage: disk).load();
        expect(restored.language, preference);
        expect(restored.theme, ThemePreference.light);
        expect(restored.favorites.map((id) => id.value), {'DE', 'US'});
        expect(restored.recent.map((id) => id.value), ['JP', 'PE']);
        final json = disk.values.values.single;
        expect(json, isNot(contains('Germany')));
        expect(json, isNot(contains('Alemania')));
      },
    );
  }

  for (final locale in [
    const Locale('en'),
    const Locale('es', 'PE'),
    const Locale('es', 'ES'),
    const Locale('fr'),
    const Locale('ja'),
  ]) {
    testWidgets('System resolves $locale to Spanish or English fallback', (
      tester,
    ) async {
      final store = MemoryPreferencesStore();
      await launch(tester, store: store, locale: locale);
      expect(
        store.value.language,
        locale.languageCode == 'es'
            ? LanguagePreference.spanish
            : LanguagePreference.english,
      );
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
        Locale(locale.languageCode == 'es' ? 'es' : 'en'),
      );
      expect(activeLocale(tester), locale.languageCode == 'es' ? 'es' : 'en');
    });
  }

  testWidgets(
    'explicit languages update before pending save and ignore OS changes',
    (tester) async {
      final store = PendingStore();
      addTearDown(() {
        if (!store.gate.isCompleted) store.gate.complete();
      });
      await launch(tester, store: store, locale: const Locale('es', 'MX'));
      await language(tester, 'English');
      expect(activeLocale(tester), 'en');
      expect(find.text(en.tagline), findsOneWidget);
      await language(tester, 'Español');
      expect(activeLocale(tester), 'es');
      expect(find.text(es.tagline), findsOneWidget);
      tester.platformDispatcher.localesTestValue = [const Locale('de')];
      await tester.pumpAndSettle();
      expect(activeLocale(tester), 'es');
      expect(store.gate.isCompleted, isFalse);
      store.gate.complete();
      await tester.pumpAndSettle();
      expect(store.value.language, LanguagePreference.spanish);
    },
  );

  testWidgets(
    'language selection restores from adapter and survives rotation independently of theme',
    (tester) async {
      final disk = MemoryStorage();
      await launch(tester, store: SharedPreferencesFlagStore(storage: disk));
      await tester.tap(find.byTooltip('Switch to dark mode'));
      await tester.pumpAndSettle();
      await language(tester, 'Español');
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        AllFlagApp(
          repository: CountryFlagCatalog(SnapshotRepository(catalog)),
          preferencesStore: SharedPreferencesFlagStore(storage: disk),
        ),
      );
      await tester.pumpAndSettle();
      expect(activeLocale(tester), 'es');
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      tester.platformDispatcher.localesTestValue = [const Locale('en')];
      for (final size in [const Size(900, 400), const Size(400, 900)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(activeLocale(tester), 'es');
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byTooltip('Cambiar a modo claro'));
      await tester.pumpAndSettle();
      expect(activeLocale(tester), 'es');
      expect(
        (await SharedPreferencesFlagStore(storage: disk).load()).language,
        LanguagePreference.spanish,
      );
    },
  );

  for (final l10n in [en, es]) {
    testWidgets(
      '${l10n.localeName} localized UI, live search, semantics and empty state',
      (tester) async {
        await launch(tester, locale: Locale(l10n.localeName));
        expect(find.text(l10n.tagline), findsOneWidget);
        expect(find.text(l10n.chooseCountry), findsOneWidget);
        expect(find.text(l10n.allCountries), findsOneWidget);
        expect(find.text(l10n.searchCountries), findsOneWidget);
        expect(find.byTooltip(l10n.language), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'peru');
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(ListTile, l10n.countryName('PE')),
          findsOneWidget,
        );
        final semantics = tester.ensureSemantics();
        expect(
          find.bySemanticsLabel(l10n.addFavorite(l10n.countryName('PE'))),
          findsOneWidget,
        );
        await tester.tap(
          find.byTooltip(l10n.addFavorite(l10n.countryName('PE'))),
        );
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel(l10n.removeFavorite(l10n.countryName('PE'))),
          findsOneWidget,
        );
        semantics.dispose();
        expect(find.text(l10n.favorites), findsNothing);
        expect(find.text(l10n.recent), findsNothing);
        await tester.enterText(find.byType(TextField), 'Atlantis');
        await tester.pumpAndSettle();
        expect(find.text(l10n.noCountries), findsOneWidget);
        expect(find.text(l10n.searchHelp), findsOneWidget);
        expect(find.byTooltip(l10n.clearSearch), findsOneWidget);
      },
    );
  }

  testWidgets(
    'favorites, recents, selected identity and fullscreen survive language changes',
    (tester) async {
      final store = MemoryPreferencesStore(
        FlagPreferences(
          favorites: ['DE'].map(flagId),
          recent: ['PE', 'DE'].map(flagId),
        ),
      );
      await launch(tester, store: store);
      expect(find.widgetWithText(ListTile, 'Germany'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('Favorites-country:DE')));
      await tester.pumpAndSettle();
      await language(tester, 'Español');
      expect(find.text('Favoritos'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Alemania'), findsWidgets);
      expect(find.text('Recientes'), findsOneWidget);
      expect(store.value.favorites.map((id) => id.value), {'DE'});
      expect(store.value.recent.map((id) => id.value), ['DE', 'PE']);
      expect(
        tester
            .widget<ListTile>(
              find.byKey(const ValueKey('Favorites-country:DE')),
            )
            .selected,
        isTrue,
      );
      expect(find.text(es.countrySelected('Alemania')), findsOneWidget);
      tester.view.physicalSize = const Size(900, 400);
      await tester.pumpAndSettle();
      expect(find.byType(FlagScreen), findsOneWidget);
      expect(find.byType(Text), findsNothing);
      final flag = tester.widget<Image>(find.byType(Image));
      expect(flag.fit, BoxFit.contain);
      expect((flag.image as AssetImage).assetName, 'assets/flags/de.png');
      expect(flag.semanticLabel, 'Bandera de Alemania');
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        Colors.black,
      );
      tester.view.physicalSize = const Size(400, 900);
      await tester.pumpAndSettle();
      await language(tester, 'English');
      expect(find.widgetWithText(ListTile, 'Germany'), findsWidgets);
      expect(store.value.favorites.map((id) => id.value), {'DE'});
      expect(store.value.recent.map((id) => id.value), ['DE', 'PE']);
    },
  );

  for (final width in [320.0, 375.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Spanish names safely render at $width and text scale $scale',
        (tester) async {
          await launch(
            tester,
            locale: const Locale('es'),
            size: Size(width, 900),
            scale: scale,
          );
          await tester.scrollUntilVisible(
            find.text('Todos los países'),
            150,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.text('Todos los países'), findsOneWidget);
          await tester.scrollUntilVisible(
            find.byType(TextField),
            -150,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          for (final name in [
            'República Centroafricana',
            'Emiratos Árabes Unidos',
            'San Vicente y las Granadinas',
          ]) {
            await tester.enterText(find.byType(TextField), name);
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.byType(ListTile),
              150,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.ensureVisible(find.byType(ListTile));
            await tester.pumpAndSettle();
            await tester.tap(
              find.descendant(
                of: find.byType(ListTile),
                matching: find.text(name),
              ),
            );
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.byType(ListTile),
              150,
              scrollable: find.byType(Scrollable).first,
            );
            final title = tester.getRect(
              find.descendant(
                of: find.byType(ListTile),
                matching: find.text(name),
              ),
            );
            final favorite = tester.getRect(
              find.byTooltip(es.addFavorite(name)),
            );
            if (width < 360 || scale == 2) {
              // Actions move below the name; retain non-overlap and add a
              // readable-width assertion for the responsive arrangement.
              expect(title.bottom, lessThanOrEqualTo(favorite.top));
              expect(title.width, greaterThanOrEqualTo(width - 132));
            } else {
              expect(title.right, lessThanOrEqualTo(favorite.left));
            }
            expect(
              tester.widget<ListTile>(find.byType(ListTile)).selected,
              isTrue,
            );
            expect(tester.takeException(), isNull);
            await tester.scrollUntilVisible(
              find.byType(TextField),
              -150,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
          }
          await language(tester, 'English');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
