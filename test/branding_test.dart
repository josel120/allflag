import 'package:allflag/data/country_flag_catalog.dart';

import 'support/flag_fixtures.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:allflag/app.dart';
import 'package:allflag/data/local_country_repository.dart';
import 'package:allflag/domain/flag_preferences.dart';
import 'package:allflag/ui/brand_theme.dart';
import 'package:allflag/ui/flag_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_preferences_store.dart';
import 'widget_test.dart' show SnapshotRepository;

const capture = bool.fromEnvironment('ALLFLAG_CAPTURE');
const fontDirectory = String.fromEnvironment('ALLFLAG_FONT_DIR');
final captureKey = GlobalKey();

Future<void> screenshot(WidgetTester tester, String name) async {
  if (!capture) return;
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/screenshots/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> launch(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
  Size size = const Size(400, 900),
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final countries = await tester.runAsync(
    () => const LocalCountryRepository().loadCountries(),
  );
  if (capture && fontDirectory.isNotEmpty) {
    await tester.runAsync(() async {
      final loader = FontLoader('Roboto');
      for (final file in ['roboto-regular.ttf', 'roboto-bold.ttf']) {
        loader.addFont(
          File('$fontDirectory/$file')
              .readAsBytes()
              .then((bytes) => ByteData.sublistView(bytes)),
        );
      }
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
  }
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: AllFlagApp(
        repository: CountryFlagCatalog(SnapshotRepository(countries!)),
        preferencesStore: MemoryPreferencesStore(
          FlagPreferences(
            favorites: ['CA', 'US'].map(flagId),
            recent: ['PE'].map(flagId),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    for (final scene in ['home', 'language', 'search']) {
      testWidgets('Spanish visual preview ${brightness.name} $scene', (
        tester,
      ) async {
        await launch(tester, brightness: brightness);
        await tester.tap(find.byIcon(Icons.language));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Español'));
        await tester.pumpAndSettle();
        expect(find.text('Tu país. Tu bandera.'), findsOneWidget);
        expect(find.text('Todos los países'), findsOneWidget);
        if (scene == 'language') {
          await tester.tap(find.byIcon(Icons.language));
          await tester.pumpAndSettle();
        } else if (scene == 'search') {
          await tester.enterText(
            find.byType(TextField),
            'República Centroafricana',
          );
          await tester.pumpAndSettle();
        }
        await screenshot(tester, '$scene-es-${brightness.name}');
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets(
      '${brightness.name} identity, sections, empty state and fullscreen',
      (tester) async {
        await launch(tester, brightness: brightness);
        expect(find.text('AllFlag'), findsOneWidget);
        expect(find.text('Your country. Your flag.'), findsOneWidget);
        expect(find.text('Favorites'), findsOneWidget);
        expect(find.text('Recent'), findsOneWidget);
        expect(find.text('All Countries'), findsOneWidget);
        expect(find.byIcon(Icons.public_rounded), findsOneWidget);
        final context = tester.element(find.byType(TextField));
        expect(Theme.of(context).brightness, brightness);
        expect(
          Theme.of(context).scaffoldBackgroundColor,
          brightness == Brightness.dark
              ? BrandTokens.darkBackground
              : BrandTokens.lightBackground,
        );
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
          ThemeMode.system,
        );
        await screenshot(tester, 'home-${brightness.name}');
        await tester.enterText(find.byType(TextField), 'Atlantis');
        await tester.pumpAndSettle();
        expect(find.text('No countries found'), findsOneWidget);
        expect(
          find.text('Try a different name or check the spelling.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
        await screenshot(tester, 'empty-${brightness.name}');
        await tester.enterText(find.byType(TextField), 'Canada');
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ListTile));
        await tester.pumpAndSettle();
        expect(tester.widget<ListTile>(find.byType(ListTile)).selected, isTrue);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(
          Theme.of(context).listTileTheme.selectedTileColor,
          isNot(Theme.of(context).listTileTheme.tileColor),
        );
        final semantics = tester.ensureSemantics();
        expect(
          find.bySemanticsLabel('Remove Canada from favorites'),
          findsOneWidget,
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        semantics.dispose();
        await screenshot(tester, 'selected-${brightness.name}');
        tester.view.physicalSize = const Size(900, 400);
        await tester.pumpAndSettle();
        expect(find.byType(FlagScreen), findsOneWidget);
        expect(find.byType(IconButton), findsNothing);
        expect(find.text('AllFlag'), findsNothing);
        final flag = tester.widget<Image>(find.byType(Image));
        expect(flag.fit, BoxFit.contain);
        expect((flag.image as AssetImage).assetName, 'assets/flags/ca.png');
        await screenshot(tester, 'landscape-${brightness.name}');
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final width in [320.0, 375.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('long names at width $width and text scale $scale', (
        tester,
      ) async {
        await launch(tester, size: Size(width, 740), scale: scale);
        for (final name in [
          'United States',
          'United Arab Emirates',
          'Central African Republic',
          'Saint Vincent and the Grenadines',
        ]) {
          await tester.enterText(find.byType(TextField), name);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byType(ListTile));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(ListTile));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.byType(ListTile),
            150,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ListTile, name), findsOneWidget);
          expect(
            tester.widget<ListTile>(find.byType(ListTile)).selected,
            isTrue,
          );
          expect(tester.takeException(), isNull);
          final title = tester.getRect(
            find.descendant(
              of: find.byType(ListTile),
              matching: find.text(name),
            ),
          );
          final favorite = tester.getRect(
            find.byTooltip('Add $name to favorites').evaluate().isEmpty
                ? find.byTooltip('Remove $name from favorites')
                : find.byTooltip('Add $name to favorites'),
          );
          expect(title.right, lessThanOrEqualTo(favorite.left));
          await tester.ensureVisible(find.byType(TextField));
        }
        if (width == 320 && scale == 2) {
          await screenshot(tester, 'small-phone-large-text');
        }
      });
    }
  }
}
