import 'package:allflag/data/country_flag_catalog.dart';

import 'support/flag_fixtures.dart';

import 'package:allflag/app.dart';
import 'package:allflag/data/local_country_repository.dart';
import 'package:allflag/domain/country.dart';
import 'package:allflag/domain/flag_preferences.dart';
import 'package:allflag/l10n/generated/app_localizations.dart';
import 'package:allflag/ui/brand_header.dart';
import 'package:allflag/ui/flag_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_preferences_store.dart';
import 'support/recording_flag_mode_platform.dart';
import 'widget_test.dart' show SnapshotRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Country> catalog;
  setUpAll(() async {
    catalog = await const LocalCountryRepository().loadCountries();
  });

  Future<void> start(
    WidgetTester tester,
    RecordingFlagModePlatform platform, {
    MemoryPreferencesStore? store,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      AllFlagApp(
        repository: CountryFlagCatalog(SnapshotRepository(catalog)),
        preferencesStore: store ?? MemoryPreferencesStore(),
        flagModePlatform: platform,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, String code) async {
    await tester.enterText(find.byType(TextField), code);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('country:$code')),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(ValueKey('country:$code')));
    await tester.pumpAndSettle();
  }

  Future<void> rotate(WidgetTester tester, bool landscape) async {
    tester.view.physicalSize = landscape
        ? const Size(900, 400)
        : const Size(400, 900);
    await tester.pumpAndSettle();
  }

  testWidgets('portrait and unselected landscape stay normal and allow sleep', (
    tester,
  ) async {
    final platform = RecordingFlagModePlatform();
    await start(tester, platform);
    expect(find.byType(FlagScreen), findsNothing);
    expect(platform.calls, [false]);
    await rotate(tester, true);
    expect(find.byType(FlagScreen), findsNothing);
    expect(find.byType(BrandHeader), findsOneWidget);
    expect(platform.awake, isFalse);
    expect(platform.calls, [false]);
    await rotate(tester, false);
    await select(tester, 'US');
    expect(find.byType(FlagScreen), findsNothing);
    expect(platform.calls, [false]);
  });

  for (final theme in ThemePreference.values) {
    testWidgets(
      'Flag Mode is only the untinted flag on black in ${theme.name}',
      (tester) async {
        final platform = RecordingFlagModePlatform();
        await start(
          tester,
          platform,
          store: MemoryPreferencesStore(FlagPreferences(theme: theme)),
        );
        await select(tester, 'US');
        await rotate(tester, true);
        expect(find.byType(FlagScreen), findsOneWidget);
        expect(platform.calls, [false, true]);
        expect(platform.awake, isTrue);
        expect(platform.immersive, isTrue);
        expect(find.byType(BrandHeader), findsNothing);
        expect(find.byType(Text), findsNothing);
        expect(find.byType(IconButton), findsNothing);
        expect(find.byType(AppBar), findsNothing);
        expect(find.byIcon(Icons.close), findsNothing);
        expect(find.byIcon(Icons.language), findsNothing);
        expect(find.text('United States'), findsNothing);
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          Colors.black,
        );
        final flag = tester.widget<Image>(find.byType(Image));
        expect(flag.fit, BoxFit.contain);
        expect(flag.color, isNull);
        expect((flag.image as AssetImage).assetName, 'assets/flags/us.png');
        await rotate(tester, false);
        expect(platform.calls, [false, true, false]);
        expect(platform.awake, isFalse);
        expect(find.byType(BrandHeader), findsOneWidget);
      },
    );
  }

  for (final code in ['US', 'CA', 'CH', 'NP']) {
    testWidgets(
      '$code retains source proportions and local image cache across rotations',
      (tester) async {
        final platform = RecordingFlagModePlatform();
        await start(tester, platform);
        await select(tester, code);
        await rotate(tester, true);
        final widget = tester.widget<Image>(find.byType(Image));
        await tester.runAsync(
          () => precacheImage(widget.image, tester.element(find.byType(Image))),
        );
        await tester.pumpAndSettle();
        final render = tester.renderObject<RenderImage>(find.byType(RawImage));
        final source = render.image!;
        final sourceSize = Size(
          source.width.toDouble(),
          source.height.toDouble(),
        );
        final fitted = applyBoxFit(render.fit!, sourceSize, render.size);
        expect(fitted.source, sourceSize);
        expect(
          fitted.destination.aspectRatio,
          closeTo(sourceSize.aspectRatio, 0.000001),
        );
        if (code == 'US') expect(sourceSize.aspectRatio, closeTo(1.9, 0.002));
        if (code == 'CA') expect(sourceSize.aspectRatio, closeTo(2, 0.002));
        if (code == 'CH') {
          expect(fitted.destination.width, fitted.destination.height);
          expect(fitted.destination.width, 400);
        }
        if (code == 'NP') {
          expect(fitted.destination.width, lessThan(fitted.destination.height));
        }
        expect(fitted.destination.width, lessThan(render.size.width));
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          Colors.black,
        );
        final cacheKey = await widget.image.obtainKey(ImageConfiguration.empty);
        expect(
          PaintingBinding.instance.imageCache.containsKey(cacheKey),
          isTrue,
        );
        await rotate(tester, false);
        await rotate(tester, true);
        final again = tester.widget<Image>(find.byType(Image));
        expect(again.image, widget.image);
        expect(
          PaintingBinding.instance.imageCache.containsKey(cacheKey),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'repeated rotations preserve selection, search, favorites, recents, theme and language',
    (tester) async {
      final platform = RecordingFlagModePlatform();
      final store = MemoryPreferencesStore(
        FlagPreferences(
          favorites: ['CH'].map(flagId),
          recent: ['NP', 'CA'].map(flagId),
          theme: ThemePreference.dark,
          language: LanguagePreference.spanish,
        ),
      );
      await start(tester, platform, store: store);
      await select(tester, 'CH');
      for (var i = 0; i < 4; i++) {
        await rotate(tester, true);
        expect(
          tester.widget<FlagScreen>(find.byType(FlagScreen)).item.id.value,
          'CH',
        );
        expect(
          tester.widget<Image>(find.byType(Image)).semanticLabel,
          'Bandera de Suiza',
        );
        expect(platform.awake, isTrue);
        await rotate(tester, false);
        expect(platform.awake, isFalse);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('country:CH')),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          tester
              .widget<ListTile>(find.byKey(const ValueKey('country:CH')))
              .selected,
          isTrue,
        );
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'CH',
        );
        expect(find.text('Tu país. Tu bandera.'), findsOneWidget);
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
          ThemeMode.dark,
        );
        expect(store.value.favorites.map((id) => id.value), {'CH'});
        expect(store.value.recent.map((id) => id.value), ['CH', 'NP', 'CA']);
        expect(store.value.language, LanguagePreference.spanish);
        expect(store.value.theme, ThemePreference.dark);
      }
      expect(platform.calls, [
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
      ]);
    },
  );

  testWidgets(
    'insets, theme and language rebuilds do not reconfigure platform state',
    (tester) async {
      final platform = RecordingFlagModePlatform();
      await start(tester, platform);
      await select(tester, 'US');
      await rotate(tester, true);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      tester.platformDispatcher.localesTestValue = [const Locale('es')];
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      for (var i = 0; i < 5; i++) {
        tester.view.padding = FakeViewPadding(top: i.toDouble());
        await tester.pumpAndSettle();
      }
      addTearDown(tester.view.resetPadding);
      expect(platform.calls, [false, true]);
      expect(
        tester.widget<Image>(find.byType(Image)).semanticLabel,
        'Bandera de Estados Unidos',
      );
      await rotate(tester, false);
      final context = tester.element(find.byType(TextField));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(AppLocalizations.of(context).localeName, 'es');
      expect(platform.calls, [false, true, false]);
    },
  );

  testWidgets(
    'background and resume restore Flag Mode only after current orientation is known',
    (tester) async {
      final platform = RecordingFlagModePlatform();
      await start(tester, platform);
      await select(tester, 'US');
      await rotate(tester, true);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(platform.awake, isFalse);
      expect(platform.immersive, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(platform.calls, [false, true, false]);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(platform.calls, [false, true, false, true]);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      // Metrics can change while frames are suppressed in the background.
      tester.view.physicalSize = const Size(400, 900);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(FlagScreen), findsNothing);
      expect(platform.calls, [false, true, false, true, false]);
      expect(platform.awake, isFalse);
    },
  );

  testWidgets(
    'disposing active Flag Mode releases screen awake and immersive state',
    (tester) async {
      final platform = RecordingFlagModePlatform();
      await start(tester, platform);
      await select(tester, 'US');
      await rotate(tester, true);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(platform.calls, [false, true, false]);
      expect(platform.awake, isFalse);
      expect(platform.immersive, isFalse);
    },
  );
}
