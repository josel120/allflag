# AllFlag 1.0.0+12 — Google Play release guide

Package `com.allflag.allflag` (permanent). Version `1.0.0+12` (pubspec.yaml;
Gradle reads it via `flutter.versionName` / `flutter.versionCode`).
Toolchain: Flutter 3.47.2 / Dart 3.13.2, JDK 17, target SDK from Flutter (36).
History of the 0.x signing investigations: git history of this file.

What changed for Play in 1.0: the app now contains **one optional rewarded ad**
("Support the developer"), so it declares ads, uses INTERNET and the
advertising ID. Everything else still works offline.

## 1. Owner steps before the first 1.0 upload

1. **AdMob** (https://admob.google.com): create the Android app linked to
   `com.allflag.allflag` and one **Rewarded** ad unit. Never commit the IDs.
2. Create the private, git-ignored `admob.json` in the repo root:

   ```json
   {
     "ALLFLAG_ADMOB_APP_ID": "ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY",
     "ALLFLAG_REWARDED_AD_UNIT_ID": "ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ"
   }
   ```

   One file configures both the manifest App ID (read by Gradle) and the Dart
   ad unit (`lib/support/ad_config.dart`). Debug/profile builds **always** use
   Google's test IDs; a release built without this file also uses test IDs.
3. **GDPR / UMP message**: in AdMob > Privacy & messaging, create and publish
   the European regulations (GDPR) message (and US states message if wanted).
   The app shows it via UMP before requesting any ad and offers "Privacy
   options" afterwards.
4. **app-ads.txt**: already published at the root of the developer website,
   `https://gaia-nexus.com/app-ads.txt` (redirects to `www`; shared with
   QrScanner). Set `https://gaia-nexus.com` as the website in the Play store
   listing so AdMob can verify it.
5. **Privacy policy**: `docs/privacy-policy/index.md` is published (repo
   `josel120/politicas`; keep both in sync) at
   `https://josel120.github.io/politicas/allflag/privacidad/` (the URL in
   `lib/privacy_policy.dart`, opened by the in-app "Privacy policy" link) and
   enter the same URL in Play Console > App content.
6. Physical QA on a real device (section 5) before uploading.

## 2. Build and sign

Signing: `android/key.properties` (ignored) points at the upload keystore in
`android/keystore/` (ignored). Release tasks fail without it; there is no
unsigned or debug-signed fallback. Never put passwords on command lines.

```sh
flutter clean
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build appbundle --release --dart-define-from-file=admob.json
```

Output: `build/app/outputs/bundle/release/app-release.aab`. R8 minification,
resource shrinking and `debugSymbolLevel = "FULL"` are on: the AAB carries the
R8 mapping and full native symbols (~110 MB of BUNDLE-METADATA that Play keeps
for crash symbolication and never ships to devices).

Verify before upload:

- `jarsigner -verify build/app/outputs/bundle/release/app-release.aab`
- Upload certificate SHA-256 matches the registered upload key
  (`9F:61:1A:…:36:23`).
- Merged manifest (`build/app/intermediates/merged_manifest/release/…`):
  `com.google.android.gms.ads.APPLICATION_ID` is your real App ID, not
  `ca-app-pub-3940256099942544~3347511713`.

## 3. Upload

Play Console > AllFlag > Testing (internal or closed) > Create release >
upload the AAB > release name `1.0.0 (12)` > notes below > review > roll out.
Keep **Play App Signing** enabled (Google holds the app signing key; you keep
the upload key, backed up outside the repo). New personal accounts need a
closed test with 12 testers for 14 days before production.

Release notes:

- EN: `AllFlag 1.0: System theme that follows your phone, clearer favorites and recents, smoother transitions, smaller download, better TalkBack support, and an optional way to support the developer.`
- ES: `AllFlag 1.0: tema del sistema que sigue a tu teléfono, favoritos y recientes más claros, transiciones más suaves, descarga más liviana, mejor soporte de TalkBack y una forma opcional de apoyar al desarrollador.`

## 4. App content declarations

**Ads**: Yes, the app contains ads (rewarded, opt-in, one screen).

**Data safety** (1.0.0+12; all collection happens in the Google Mobile Ads
SDK, only after the user opens "Support the developer"):

| Question | Answer |
| --- | --- |
| Does the app collect or share user data? | Yes |
| Device or other IDs (advertising ID) | Collected and shared; Advertising or marketing, Fraud prevention/security, Analytics. Optional (only if the user opens Support) |
| App info and performance: crash logs, diagnostics | Collected (ads SDK); Analytics, Fraud prevention |
| App activity: app interactions (ad interactions) | Collected and shared; Advertising, Analytics |
| Approximate location (from IP) | Collected and shared; Advertising |
| Encrypted in transit | Yes |
| Deletion | Held by Google; local data is removed by clearing app data or uninstalling |
| Favorites, recents, Quick Flag, theme, language, supporter count | Not collected: stored only on device, never transmitted |

Cross-check with Google's guidance for the Mobile Ads SDK
(https://developers.google.com/admob/android/privacy/play-data-disclosure),
which is authoritative for what the SDK collects.

**Advertising ID declaration**: Yes, used for advertising (AD_ID permission is
merged by the SDK).

**Target audience**: 13+ (the ad screen is not designed for children). If
children are ever targeted, Families policy and child-directed ad settings
apply first.

**Content rating**: questionnaire; no violence, UGC or gambling; ads: Yes.

**Permissions in the merged release manifest** (from the ads SDK and its
dependencies): INTERNET, ACCESS_NETWORK_STATE, AD_ID,
ACCESS_ADSERVICES_AD_ID/ATTRIBUTION/TOPICS, WAKE_LOCK, FOREGROUND_SERVICE
(WorkManager, no foreground service types). No dangerous runtime permissions.

## 5. Physical QA checklist (release gate)

- [ ] Fresh install: theme follows the OS live; Sistema/Claro/Oscuro menu
      works and persists.
- [ ] Upgrade over 0.9.0+11: favorites, recents, Quick Flag kept; theme
      looks unchanged on first open.
- [ ] Landscape shows the flag full-screen; Quick Flag works in portrait;
      exit control and back work; transitions are instant with
      Accessibility > Remove animations.
- [ ] Detailed flags (Mexico, Ecuador, Spain, Bhutan) crisp full-screen.
- [ ] TalkBack: selecting a country far down "All Countries" announces the
      confirmation once.
- [ ] Support the developer: consent message (UMP debug geography or EEA),
      test ad loads, reward increments the badge, closing early gives no
      reward, airplane mode shows the offline state.
- [ ] Privacy policy link opens the hosted page in the browser.
- [ ] 16 KB page-size device or emulator launch.

## 6. Store listing

Title `AllFlag`. Short descriptions (≤80): EN `Turn your phone into any country's flag. Rotate and display it instantly.`;
ES `Convierte tu teléfono en la bandera de tu país. Gira y muéstrala al instante.`
Do not claim "no ads" any more; "no ads except an optional way to support the
developer" is accurate. Screenshots: home light, home dark, full-screen flag,
favorites/recents with Quick Flag (1080×1920 or larger). Feature graphic
1024×500: `assets/branding/grafico.png`.
