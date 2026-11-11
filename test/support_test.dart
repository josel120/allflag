import 'dart:async';

import 'package:allflag/app.dart';
import 'package:allflag/data/country_flag_catalog.dart';
import 'package:allflag/domain/flag_preferences.dart';
import 'package:allflag/privacy_policy.dart' as privacy;
import 'package:allflag/support/ad_config.dart';
import 'package:allflag/support/support_ad_service.dart';
import 'package:allflag/support/supporter_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_preferences_store.dart';
import 'widget_test.dart' show SnapshotRepository;

class FakeAdService implements SupportAdService {
  SupportAdFailure? prepareFailure;
  SupportAdFailure? loadFailure;
  bool earn = true;
  bool privacyRequired = false;
  final calls = <String>[];
  Completer<void>? loadGate;

  @override
  Future<void> prepare() async {
    calls.add('prepare');
    if (prepareFailure case final f?) throw SupportAdException(f);
  }

  @override
  Future<bool> privacyOptionsRequired() async => privacyRequired;

  @override
  Future<void> showPrivacyOptions() async => calls.add('privacy');

  @override
  Future<void> load() async {
    calls.add('load');
    await loadGate?.future;
    if (loadFailure case final f?) throw SupportAdException(f);
  }

  @override
  Future<bool> show() async {
    calls.add('show');
    return earn;
  }

  @override
  void dispose() => calls.add('dispose');
}

void main() {
  group('AdConfig', () {
    const real = 'ca-app-pub-1234567890123456/1234567890';
    test('debug and profile always use Google test IDs', () {
      expect(
        AdConfig.rewardedUnitId(release: false, configured: real),
        AdConfig.testRewardedUnitId,
      );
      expect(AdConfig.usesRealAds(release: false, configured: real), isFalse);
    });
    test('release uses the configured real ID only when well formed', () {
      expect(AdConfig.rewardedUnitId(release: true, configured: real), real);
      for (final bad in ['', 'TODO', 'ca-app-pub-123/456']) {
        expect(
          AdConfig.rewardedUnitId(release: true, configured: bad),
          AdConfig.testRewardedUnitId,
        );
      }
    });
    test('this test build is not wired to real ads', () {
      expect(AdConfig.usesRealAds(), isFalse);
      expect(
        AdConfig.testRewardedUnitId,
        startsWith('ca-app-pub-3940256099942544/'),
      );
    });
  });

  late FakeAdService ads;
  late MemorySupporterStore supporters;
  late int created;
  late List<Uri> opened;
  late bool openResult;

  Future<void> start(WidgetTester tester, {String? locale}) async {
    created = 0;
    opened = [];
    openResult = true;
    ads = FakeAdService();
    supporters = MemorySupporterStore();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      AllFlagApp(
        repository: CountryFlagCatalog(SnapshotRepository([])),
        preferencesStore: MemoryPreferencesStore(
          FlagPreferences(
            language: locale == 'es'
                ? LanguagePreference.spanish
                : LanguagePreference.english,
          ),
        ),
        adServiceFactory: () {
          created++;
          return ads;
        },
        supporterStore: supporters,
        openUrl: (uri) async {
          opened.add(uri);
          return openResult;
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSupport(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('support-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('ads SDK is untouched until Support is opened', (tester) async {
    await start(tester);
    expect(created, 0);
    expect(find.byKey(const ValueKey('support-card')), findsOneWidget);
    await openSupport(tester);
    expect(created, 1);
    expect(ads.calls, ['prepare', 'load']);
  });

  for (final locale in ['en', 'es']) {
    testWidgets('$locale reward is stated first, earned once, persisted', (
      tester,
    ) async {
      await start(tester, locale: locale);
      await openSupport(tester);
      expect(
        find.text(
          locale == 'es'
              ? 'Tu recompensa: un mensaje de agradecimiento y +1 en tu insignia de apoyo. Nada de la app está bloqueado.'
              : 'Your reward: a thank-you message and +1 on your supporter badge. Nothing in the app is locked.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          locale == 'es' ? 'Aún no has apoyado' : "You haven't supported yet",
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('support-watch')));
      await tester.pumpAndSettle();
      expect(supporters.count, 1);
      expect(
        find.text(
          locale == 'es' ? 'Has apoyado 1 vez' : "You've supported once",
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          locale == 'es'
              ? '¡Gracias! Tu apoyo mantiene vivo AllFlag.'
              : 'Thank you! Your support keeps AllFlag going.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('support-retry')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('support-watch')));
      await tester.pumpAndSettle();
      expect(supporters.count, 2);
      expect(
        find.text(
          locale == 'es' ? 'Has apoyado 2 veces' : "You've supported 2 times",
        ),
        findsOneWidget,
      );
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(ads.calls.last, 'dispose');
    });
  }

  testWidgets('closing early gives no reward', (tester) async {
    await start(tester);
    ads.earn = false;
    await openSupport(tester);
    await tester.tap(find.byKey(const ValueKey('support-watch')));
    await tester.pumpAndSettle();
    expect(supporters.count, 0);
    expect(find.textContaining('no reward this time'), findsOneWidget);
  });

  testWidgets('loading state disables the button until the ad is ready', (
    tester,
  ) async {
    await start(tester);
    ads.loadGate = Completer<void>();
    await tester.tap(find.byKey(const ValueKey('support-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Loading ad…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('support-watch')))
          .onPressed,
      isNull,
    );
    ads.loadGate!.complete();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('support-watch')))
          .onPressed,
      isNotNull,
    );
  });

  for (final (failure, text) in [
    (SupportAdFailure.unavailable, 'No ad is available right now'),
    (SupportAdFailure.offline, "You're offline"),
    (SupportAdFailure.error, 'Something went wrong'),
  ]) {
    testWidgets('$failure shows its state and retries', (tester) async {
      await start(tester);
      ads.loadFailure = failure;
      await openSupport(tester);
      expect(find.textContaining(text), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('support-watch')))
            .onPressed,
        isNull,
      );
      ads.loadFailure = null;
      await tester.tap(find.byKey(const ValueKey('support-retry')));
      await tester.pumpAndSettle();
      expect(find.textContaining(text), findsNothing);
      expect(supporters.count, 0);
    });
  }

  testWidgets('consent denied offers Privacy options and never loads', (
    tester,
  ) async {
    await start(tester);
    ads.prepareFailure = SupportAdFailure.consentDenied;
    await openSupport(tester);
    expect(ads.calls, ['prepare']);
    expect(find.textContaining('privacy choices'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('support-privacy-options')));
    await tester.pumpAndSettle();
    expect(ads.calls, contains('privacy'));
  });

  testWidgets('privacy options entry appears when UMP requires it', (
    tester,
  ) async {
    await start(tester);
    ads.privacyRequired = true;
    await openSupport(tester);
    expect(
      find.byKey(const ValueKey('support-privacy-options')),
      findsOneWidget,
    );
  });

  testWidgets('privacy policy opens the hosted page; failure is explained', (
    tester,
  ) async {
    await start(tester);
    final link = find.byKey(const ValueKey('privacy-policy'));
    await tester.scrollUntilVisible(
      link,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(opened, [Uri.parse(privacy.privacyPolicyUrl)]);
    expect(privacy.privacyPolicyUrl, startsWith('https://'));
    openResult = false;
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(
      find.text('Could not open the privacy policy. Try again later.'),
      findsOneWidget,
    );
  });

  testWidgets('rotating under the support screen never enters Flag Mode', (
    tester,
  ) async {
    await start(tester);
    await openSupport(tester);
    tester.view.physicalSize = const Size(900, 400);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('support-watch')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
