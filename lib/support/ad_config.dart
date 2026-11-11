import 'package:flutter/foundation.dart';

/// Single source of AdMob IDs.
///
/// Debug and profile builds ALWAYS use Google's official test IDs, whatever is
/// configured. Release builds use the owner's real IDs only when they are
/// passed at build time (never committed):
///
///   flutter build appbundle --release --dart-define-from-file=admob.json
///
/// where the private, git-ignored `admob.json` contains
///   {"ALLFLAG_ADMOB_APP_ID": "ca-app-pub-XXXX~YYYY",
///    "ALLFLAG_REWARDED_AD_UNIT_ID": "ca-app-pub-XXXX/ZZZZ"}
/// Gradle reads the same dart-define for the manifest App ID.
///
/// TODO(owner): create the AdMob app and rewarded unit, then fill admob.json.
abstract final class AdConfig {
  /// Google's sample AdMob App ID for Android.
  static const testAppId = 'ca-app-pub-3940256099942544~3347511713';

  /// Google's sample rewarded ad unit for Android.
  static const testRewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';

  static const _configuredRewardedUnitId = String.fromEnvironment(
    'ALLFLAG_REWARDED_AD_UNIT_ID',
  );

  /// Real IDs look like `ca-app-pub-<16 digits>/<10 digits>`.
  static final _unitIdPattern = RegExp(r'^ca-app-pub-\d{16}/\d{10}$');

  static String rewardedUnitId({
    bool release = kReleaseMode,
    String configured = _configuredRewardedUnitId,
  }) => release && _unitIdPattern.hasMatch(configured)
      ? configured
      : testRewardedUnitId;

  /// True when this build would show live ads (for docs/diagnostics only).
  static bool usesRealAds({
    bool release = kReleaseMode,
    String configured = _configuredRewardedUnitId,
  }) =>
      rewardedUnitId(release: release, configured: configured) !=
      testRewardedUnitId;
}
