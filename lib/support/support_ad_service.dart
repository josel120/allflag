import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

enum SupportAdFailure { unavailable, offline, error, consentDenied }

class SupportAdException implements Exception {
  const SupportAdException(this.failure);
  final SupportAdFailure failure;
  @override
  String toString() => 'SupportAdException($failure)';
}

/// The only door to the ads SDK. Nothing touches the network until the user
/// opens "Support the developer"; tests use a fake.
abstract interface class SupportAdService {
  /// UMP consent (form if required), then lazy MobileAds init.
  Future<void> prepare();
  Future<bool> privacyOptionsRequired();
  Future<void> showPrivacyOptions();

  /// Loads one rewarded ad. Throws [SupportAdException].
  Future<void> load();

  /// Shows the loaded ad; true only when the reward was earned.
  Future<bool> show();
  void dispose();
}

class GoogleSupportAdService implements SupportAdService {
  GoogleSupportAdService({String? unitId})
    : _unitId = unitId ?? AdConfig.rewardedUnitId();
  final String _unitId;
  RewardedAd? _ad;
  static bool _initialized = false;

  @override
  Future<void> prepare() async {
    final updated = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      updated.complete,
      // Usually no network; a cached decision may still allow ads.
      (_) => updated.complete(),
    );
    await updated.future;
    await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
    if (!await ConsentInformation.instance.canRequestAds()) {
      final status = await ConsentInformation.instance.getConsentStatus();
      throw SupportAdException(
        status == ConsentStatus.unknown
            ? SupportAdFailure.offline
            : SupportAdFailure.consentDenied,
      );
    }
    if (!_initialized) {
      await MobileAds.instance.initialize();
      _initialized = true;
    }
  }

  @override
  Future<bool> privacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  @override
  Future<void> showPrivacyOptions() =>
      ConsentForm.showPrivacyOptionsForm((_) {});

  @override
  Future<void> load() async {
    _ad?.dispose();
    _ad = null;
    final loaded = Completer<RewardedAd>();
    await RewardedAd.load(
      adUnitId: _unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: loaded.complete,
        onAdFailedToLoad: (error) => loaded.completeError(
          SupportAdException(switch (error.code) {
            2 => SupportAdFailure.offline, // ERROR_CODE_NETWORK_ERROR
            3 => SupportAdFailure.unavailable, // ERROR_CODE_NO_FILL
            9 => SupportAdFailure.unavailable, // ERROR_CODE_MEDIATION_NO_FILL
            _ => SupportAdFailure.error,
          }),
        ),
      ),
    );
    _ad = await loaded.future;
  }

  @override
  Future<bool> show() async {
    final ad = _ad;
    if (ad == null) throw const SupportAdException(SupportAdFailure.error);
    _ad = null;
    final done = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!done.isCompleted) {
          done.completeError(const SupportAdException(SupportAdFailure.error));
        }
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return done.future;
  }

  @override
  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
