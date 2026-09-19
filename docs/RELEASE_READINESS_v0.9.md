# AllFlag v0.9.0+11 release candidate readiness

This is a pre-1.0 hardening release. The production catalog remains 195 countries;
no catalogs, dependencies, languages, networking, branding or product scope were
added. No upload or Git tag is authorized by this preparation. Physical QA is the
release gate. See [generic architecture](FLAG_CATALOG_ARCHITECTURE.md) for the
existing domain and migration design rather than duplicating it here.

## Quick Flag presentation and restoration

Quick Flag is an explicit presentation session, independent of whether Android
honors the landscape request. The controller passes its programmatic state to the
platform adapter. Android receives `setQuickFlagMode(true)` for explicit entry;
ordinary `setFlagMode(bool)` continues to represent physical-rotation entry and
all exits. Both messages share the same native insets/KEEP_SCREEN_ON implementation.

- Landscape succeeds: show the same contain-fit artwork, immersive bars and awake
  request, with the existing temporary exit button and Android Back behavior.
- Landscape ignored/refused: retain the flag in the current viewport. Explicit
  native sessions permit portrait while still requiring foreground and window
  focus. Immersive bars and KEEP_SCREEN_ON are requested together.
- Ordinary rotation continues to require native landscape as well as Dart's
  selected-item/landscape condition; late messages cannot activate it in portrait.
- Inactive/hidden/paused/detached transitions release platform effects and the
  orientation request. Resume recomputes presentation and restores explicit mode.
  Native pause/focus-loss/destruction cleanup remains in place.
- Exit, Back and disposal restore system bars/default bar behavior, normal sleep,
  and an empty preferred-orientation list (the app's OS-default preference).
  Quick Flag exit clears the temporary selection, so a still-landscape viewport
  cannot immediately re-enter. Saved Quick Flag and Recent remain intact.
- Requests remain serialized and deduplicated; rebuilds do not issue extra calls.
  Orientation rejection is best-effort and does not block activation or exit.
  Platform failures still attempt cleanup and never trigger rebuild retry loops.
- Exit hides after four seconds, tap reveals it, and accessible navigation keeps
  it visible. No private APIs, brightness changes, lockout or navigation blocking.

OS/window policies still control actual bars, caption bars and rotation. Automated
channel tests prove requested transitions, not actual Android window effects.

## Readability, discovery and recovery

At widths below 360 logical pixels or enlarged text (scaled 16px text above 20px),
row actions move below the name within the existing ListTile. The 48x32 thumbnail,
Favorite, menu and selected indicator remain. Titles wrap without a line cap or
ellipsis, with unchanged accessibility scale. At 320px this gives the name 188px
instead of sharing that space with the trailing controls. Normal-width 1x rows
retain their existing compact arrangement. Favorites, Recent and catalog/search
share this behavior; the existing Quick Flag card already separates its actions.

One small English/Spanish hint beside the initial instruction explains using the
country menu to set Quick Flag. No onboarding, dialog or additional navigation.
Image-error recovery keeps rotation guidance for ordinary Flag Mode; explicit
Quick Flag tells users to reveal the exit button and close Flag Mode.

## Accessibility

The search field and brand header now have separate semantic containers: inspection
found the search text-field node previously absorbed the header and instruction.
Quick Flag's reveal action now has one localized semantic label; the inner gesture
detector no longer duplicates that action. Existing localized tooltips, Favorite toggled state, selection and exit semantics
are retained. Automated checks cover named controls and Android/iOS tap-target
guidelines where Flutter can reliably evaluate visible nodes.

The row matrix covers 320/375/430px, English/Spanish, 1x/2x, selected/unselected,
and Favorites/Recent/catalog. Tests check readable title width, wrapping policy,
thumbnail bounds and 48px icon targets. Other focused tests cover the localized
hint, mode-aware image errors, Quick Flag/exit labels, search, appearance/language,
actions menu and Favorite controls. Existing tests remain enabled.

TalkBack/VoiceOver reading order, announcements, focus after menu/exit, magnification,
Switch Access and real touch ergonomics still require physical-device testing.
Widget guidelines do not establish WCAG conformance or replace that testing.

## Privacy/data technical inventory and Android backup

The application persists Favorites, up to five Recent IDs, one optional Quick Flag,
theme and language in an on-device preferences snapshot. Current selection and
search text are session state. Preferences are identifiers and settings, not copied
flag images. All artwork and catalog data are bundled in the application.

Source/dependency review found no application networking, analytics, advertising,
tracking or authentication SDK. The production Android manifest requests no
dangerous runtime permissions. Flutter's debug/profile manifests contain INTERNET
for development tooling; those are not the release manifest. KEEP_SCREEN_ON is a
foreground window flag, not a wake-lock permission or background service.

No explicit Android backup exclusion rules are configured. Android platform backup
may therefore include preferences under OS defaults, subject to platform, device,
account and user settings. The app does not implement cloud sync. Backup has not
been disabled or changed. Do not equate local application storage with a guarantee
that the OS never backs it up. This inventory is input to later Data Safety and
privacy-policy work, not a legal conclusion or a completed store declaration.

The two failure-path debugPrint calls are retained: they diagnose orientation and
platform-transition exceptions locally, without emitting selected IDs, search text,
preference snapshots, signing material or credentials. Their inputs are platform
operations with boolean/orientation arguments, not user content; there is no log
upload SDK. They run only on failures and do not retry on rebuild. The activation
failure path still attempts system-UI, awake and orientation cleanup; the optional
error callback remains available. Review this decision if future platform handlers
start including user data in exceptions.

## Generic architecture audit

Category C (unwanted country coupling in Favorites, Recent, Quick Flag, selection,
search, Flag Mode or persistence application logic): **0**.

Application logic continues to use FlagItem, FlagId, FlagCatalog and FlagPreferences.
The new release matrix deliberately uses a synthetic non-country category. Country
names/copy and section captions are current product vocabulary; the production
country provider, historical storage key and explicit legacy ISO migration are
intentional boundaries, not new feature-level country assumptions. No category
switch, country cast or ISO validation was introduced into these features.

## Repository hygiene

The generated android/build/reports/problems/problems-report.html is removed from
Git tracking; /android/build/ is ignored. Broken GENERIC_FLAG_CATALOG.md references
now point to FLAG_CATALOG_ARCHITECTURE.md. Older release documents retain historical
versions/counts; current-behavior notes link here where later releases supersede them.
Application ID com.allflag.allflag, signing configuration, credentials, upload key
and signing identity remain unchanged.

## Physical QA release gate

- [ ] Android phone, landscape honored: both directions, auto-rotate on/off, several
  flag ratios; verify bars hide and screen remains awake beyond normal timeout.
- [ ] Android configuration refusing landscape (large-screen/multiwindow/device
  policy): portrait flag, actual immersive request behavior and screen-awake timing.
- [ ] In both cases: repeated entry/close/Back, hidden-control tap reveal, edge-swipe
  navigation, exit while landscape, and subsequent ordinary physical rotation.
- [ ] In both cases: Home/background/resume, notification shade, focus loss,
  lock/unlock, window resize/fold transitions and process recreation.
- [ ] Verify normal sleep and system bars after every exit/background, and restored
  OS orientation preferences. Confirm there is always a reachable exit.
- [ ] 320/375/430px equivalent devices, English/Spanish, 1x/2x text: long names,
  selected/unselected, Favorites/Recent/catalog/search, menus and Quick Flag card.
- [ ] TalkBack: meaningful labels, toggles/selection, search entry/clear, appearance,
  language, menu assignment/removal, Show flag, persistent/revealed exit and focus.
- [ ] Exercise bundled-image failure recovery in ordinary and explicit mode.
- [ ] Inspect privacy/backup behavior on actual supported Android configurations
  before final Data Safety/privacy-policy decisions.
- [ ] iOS macOS/Xcode build/signing and physical iPhone/iPad validation remain
  required: orientation refusal/multitasking, idle timer, overlays/home indicator,
  lifecycle/exit restoration, VoiceOver and launcher/splash. Not validated on Windows.

## Validation record

Validated on Windows on 2026-09-18:

| Check | Result |
| --- | --- |
| Dart format, --output=none --set-exit-if-changed . | 37 files, 0 changed; passed using the installed Dart SDK executable |
| flutter analyze | No issues found |
| flutter test --machine | 177 actual completed tests, all successful; 0 skipped; hidden runner events excluded |
| Original tests | All 145 retained; 32 focused release-candidate tests added |
| flutter build appbundle --release | Passed |
| Release merged manifest | com.allflag.allflag; versionName 0.9.0; versionCode 11 |
| jarsigner -verify | jar verified |
| keytool -printcert -jarfile | One signer; SHA-256 matches the required upload certificate |
| AAB | build/app/outputs/bundle/release/app-release.aab |
| Exact size | 52,064,818 bytes |
| Dependencies added / removed / upgraded | 0 / 0 / 0; pubspec.lock unchanged |
| Category C findings | 0 |

Certificate SHA-256:
`9F:61:1A:BA:E6:AC:37:EF:F0:E4:A3:73:2F:7E:E7:90:8B:75:5C:45:2D:6D:9D:AE:71:BC:74:15:89:74:36:23`.

Jarsigner also reports the existing self-signed/untrusted certificate chain, absent
timestamp and ZIP permission/symlink attribute warnings. Cryptographic verification
succeeded; these are not a claim of public-CA trust. No signing inputs were modified.
The merged release manifest has only the generated signature-level dynamic receiver
permission, no INTERNET or dangerous runtime permission, and no explicit backup rules.

Full test evidence is in the local ignored build/flutter-test-results.jsonl file;
count only testDone events with hidden=false. The original branding/localization
scenarios now tap the name and assert vertical non-overlap plus readable width for
stacked actions, preserving selection checks and horizontal separation in compact
rows. Lazy sections are scrolled into view before checking their labels. No test
was deleted, skipped or relaxed to excuse a regression.

The Dart batch launcher stalled before invoking the SDK during concurrent Flutter
work. The identical format arguments completed successfully via the installed SDK
executable. No formatter failure was suppressed.

## Changed files

- .gitignore; android/.gitignore
- pubspec.yaml (version only)
- android/app/src/main/kotlin/com/allflag/allflag/MainActivity.kt
- android/build/reports/problems/problems-report.html (untracked generated output)
- lib/platform/flag_mode_platform.dart
- lib/ui/flag_mode_controller.dart; lib/ui/flag_screen.dart
- lib/ui/home_screen.dart; lib/ui/brand_header.dart
- lib/l10n/app_en.arb; lib/l10n/app_es.arb
- lib/l10n/generated/app_localizations.dart; app_localizations_en.dart;
  app_localizations_es.dart (generated from the ARBs)
- test/release_candidate_test.dart (new)
- test/branding_test.dart; test/localization_test.dart
- test/flag_mode_controller_test.dart; test/support/recording_flag_mode_platform.dart
- README.md
- docs/FAVORITES_AND_RECENT.md; docs/LOCALIZATION.md (architecture links)
- docs/FLAG_MODE.md; docs/QUICK_FLAG.md (links and current-behavior notes)
- docs/RELEASE_READINESS_v0.9.md (this document)

Kotlin compiler session output generated by the release build is also ignored.
No physical QA has been claimed complete. Do not tag or upload until separately authorized.
