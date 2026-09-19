import 'package:allflag/app.dart';
import 'package:allflag/domain/flag_catalog.dart';
import 'package:allflag/domain/flag_id.dart';
import 'package:allflag/domain/flag_item.dart';
import 'package:allflag/domain/flag_preferences.dart';
import 'package:allflag/l10n/generated/app_localizations.dart';
import 'package:allflag/platform/flag_mode_platform.dart';
import 'package:allflag/ui/flag_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_preferences_store.dart';
import 'support/recording_flag_mode_platform.dart';

final item = FlagItem(
  id: FlagId(FlagCategory('fixture'), 'long-name'),
  asset: 'assets/flags/vc.png',
  defaultName: 'Saint Vincent and the Grenadines',
  localizedNames: {'es': 'San Vicente y las Granadinas'},
);

class SingleCatalog implements FlagCatalog {
  @override
  Future<List<FlagItem>> loadFlags() async => [item];
}

Future<void> start(
  WidgetTester tester, {
  double width = 375,
  double scale = 1,
  LanguagePreference language = LanguagePreference.english,
  FlagModePlatform? platform,
  bool quick = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpWidget(
    AllFlagApp(
      repository: SingleCatalog(),
      preferencesStore: MemoryPreferencesStore(
        FlagPreferences(
          favorites: [item.id],
          recent: [item.id],
          language: language,
          quickFlag: quick ? item.id : null,
        ),
      ),
      flagModePlatform: platform ?? RecordingFlagModePlatform(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    100,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 375.0, 430.0]) {
    for (final language in [
      LanguagePreference.english,
      LanguagePreference.spanish,
    ]) {
      for (final scale in [1.0, 2.0]) {
        for (final selected in [false, true]) {
          testWidgets(
            'readable rows $width ${language.name} ${scale}x selected=$selected',
            (tester) async {
              await start(
                tester,
                width: width,
                scale: scale,
                language: language,
              );
              final name = item.displayName(
                language == LanguagePreference.spanish ? 'es' : 'en',
              );
              if (selected) {
                final first = find.byKey(ValueKey('Favorites-${item.id}'));
                await reveal(tester, first);
                await tester.tap(
                  find.descendant(of: first, matching: find.text(name)),
                );
                await tester.pumpAndSettle();
              }
              for (final key in [
                'Favorites-${item.id}',
                'Recent-${item.id}',
                '${item.id}',
              ]) {
                final row = find.byKey(ValueKey(key));
                await reveal(tester, row);
                final tile = tester.widget<ListTile>(row);
                expect(tile.selected, selected);
                final title = find.descendant(
                  of: row,
                  matching: find.text(name),
                );
                final titleRect = tester.getRect(title);
                final bounds = tester.getRect(row);
                final constrained = width < 360 || scale == 2;
                // Constrained titles reclaim the entire trailing-control allocation.
                expect(
                  titleRect.width,
                  greaterThanOrEqualTo(constrained ? width - 132 : width - 270),
                );
                expect(titleRect.right, lessThanOrEqualTo(bounds.right - 16));
                expect(tester.widget<Text>(title).maxLines, isNull);
                expect(tester.widget<Text>(title).overflow, isNull);
                expect(
                  tester.getSize(
                    find.descendant(of: row, matching: find.byType(Image)),
                  ),
                  const Size(48, 32),
                );
                expect(tile.trailing == null, constrained);
                for (final control in [
                  find.byType(IconButton),
                  find.byType(PopupMenuButton<bool>),
                ]) {
                  final target = tester.getSize(
                    find.descendant(of: row, matching: control).first,
                  );
                  expect(target.width, greaterThanOrEqualTo(48));
                  expect(target.height, greaterThanOrEqualTo(48));
                }
                expect(tester.takeException(), isNull);
              }
            },
          );
        }
      }
    }
  }

  for (final succeeds in [true, false]) {
    testWidgets(
      'Android channel Quick Flag landscape succeeds=$succeeds repeated lifecycle and exits',
      (tester) async {
        final calls = <MethodCall>[];
        final orientations = <Object?>[];
        final messenger = tester.binding.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(NativeFlagModePlatform.channel, (
          call,
        ) async {
          calls.add(call);
          return null;
        });
        messenger.setMockMethodCallHandler(SystemChannels.platform, (
          call,
        ) async {
          if (call.method == 'SystemChrome.setPreferredOrientations') {
            orientations.add(call.arguments);
            if (succeeds) {
              tester.view.physicalSize = (call.arguments as List).isEmpty
                  ? const Size(375, 900)
                  : const Size(900, 375);
            }
          }
          return null;
        });
        addTearDown(() {
          messenger.setMockMethodCallHandler(
            NativeFlagModePlatform.channel,
            null,
          );
          messenger.setMockMethodCallHandler(SystemChannels.platform, null);
        });
        await start(
          tester,
          quick: true,
          platform: const NativeFlagModePlatform(operatingSystem: 'android'),
        );
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.text('Show flag'));
          await tester.pumpAndSettle();
          expect(find.byType(FlagScreen), findsOneWidget);
          expect(
            tester.view.physicalSize.width > tester.view.physicalSize.height,
            succeeds,
          );
          // This explicit message activates both native insets and KEEP_SCREEN_ON,
          // independent of orientation. Actual OS effects require physical QA.
          expect(calls.last.method, 'setQuickFlagMode');
          expect(calls.last.arguments, true);
          final count = calls.length;
          await tester.pump();
          await tester.pump();
          expect(calls, hasLength(count));
          for (final state in [
            AppLifecycleState.inactive,
            AppLifecycleState.hidden,
            AppLifecycleState.paused,
          ]) {
            tester.binding.handleAppLifecycleStateChanged(state);
            await tester.pumpAndSettle();
            expect(calls.last.method, 'setFlagMode');
            expect(calls.last.arguments, false);
            expect(orientations.last, isEmpty);
          }
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pumpAndSettle();
          expect(calls.last.method, 'setQuickFlagMode');
          expect(orientations.last, [
            'DeviceOrientation.landscapeLeft',
            'DeviceOrientation.landscapeRight',
          ]);
          if (i == 1) {
            await tester.binding.handlePopRoute();
          } else {
            await tester.tap(find.byTooltip('Exit Flag Mode'));
          }
          await tester.pumpAndSettle();
          expect(find.byType(FlagScreen), findsNothing);
          expect(calls.last.method, 'setFlagMode');
          expect(calls.last.arguments, false);
          expect(orientations.last, isEmpty);
        }
        await tester.tap(find.text('Show flag'));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        expect(calls.last.arguments, false);
        expect(orientations.last, isEmpty);
      },
    );
  }

  for (final locale in ['en', 'es']) {
    testWidgets('localized hint and accessible Home controls $locale', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await start(
          tester,
          quick: true,
          language: locale == 'en'
              ? LanguagePreference.english
              : LanguagePreference.spanish,
        );
        final l10n = AppLocalizations.of(
          tester.element(find.byType(TextField)),
        );
        expect(find.text(l10n.quickFlagHint), findsOneWidget);
        expect(
          l10n.quickFlagHint,
          locale == 'en'
              ? "Use a country's menu to set a Quick Flag."
              : 'Usa el menú de un país para fijar una bandera rápida.',
        );
        for (final label in [
          l10n.switchToDarkMode,
          l10n.language,
          l10n.countryActions(item.displayName(locale)),
        ]) {
          expect(find.byTooltip(label), findsWidgets);
        }
        expect(
          find.bySemanticsLabel(l10n.showFlagLabel(item.displayName(locale))),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel(l10n.searchCountries), findsOneWidget);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await tester.tap(find.text(l10n.showFlag));
        await tester.pumpAndSettle();
        expect(
          tester
              .getSemantics(find.byTooltip(l10n.exitFlag))
              .getSemanticsData()
              .tooltip,
          l10n.exitFlag,
        );
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await tester.tap(find.byTooltip(l10n.exitFlag));
        await tester.pumpAndSettle();
        final row = find.byKey(ValueKey('Favorites-${item.id}'));
        await reveal(tester, row);
        expect(
          find.bySemanticsLabel(l10n.removeFavorite(item.displayName(locale))),
          findsWidgets,
        );
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await tester.tap(
          find.descendant(
            of: row,
            matching: find.byType(PopupMenuButton<bool>),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel(l10n.removeQuickFlag), findsOneWidget);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      } finally {
        semantics.dispose();
      }
    });
    for (final quick in [false, true]) {
      testWidgets('image recovery $locale Quick Flag=$quick', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: FlagScreen(item: item, onExit: quick ? () {} : null),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(FlagScreen));
        final l10n = AppLocalizations.of(context);
        final image = tester.widget<Image>(find.byType(Image));
        final recovery = image.errorBuilder!(
          context,
          StateError('asset unavailable'),
          null,
        ) as Center;
        expect(
          (recovery.child! as Text).data,
          quick ? l10n.quickFlagUnavailable : l10n.flagUnavailable,
        );
        expect(l10n.quickFlagUnavailable, isNot(l10n.flagUnavailable));
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
