# Favorites and Recent — v0.3.0+5

> v0.8 update: core features now use FlagItem/FlagId and FlagPreferences.
> Country-only persistence details below describe the original release; see
> [Generic Flag Catalog and migration](GENERIC_FLAG_CATALOG.md) for the current schema.
> User-facing behavior and device QA expectations remain unchanged.

The existing country selector now has optional Favorites and Recent sections,
followed by All Countries. Favorites are alphabetical, unique within their
section, and remain in the full catalog. Recent contains at most five unique
countries, most recently selected first. Selecting a recent country moves it to
the front. Favorite toggles do not select a country or change Recent.

Any non-whitespace search hides the section headings and shortcut rows and uses
the existing case-insensitive partial-name/code search. Clearing search restores
the sections. Stars have explicit add/remove accessibility labels, while the
selected-country checkmark remains a separate indicator. Headings have header
semantics. All rows remain lazily built with small decoded thumbnails.

## Persistence architecture

- CountryPreferences is an immutable snapshot containing only ISO country codes.
  It deduplicates favorites/recents, caps Recent at five, and filters codes not in
  the loaded 195-country catalog. Selection and search text remain session-only.
- CountryPreferencesStore is the UI-facing load/save interface.
- SharedPreferencesCountryStore stores a single JSON snapshot under
  allflag.country_preferences.v1 with favorites and recent string arrays. A
  single write prevents partially updating the two sections.
- shared_preferences 2.5.5 is the only new direct runtime dependency. It avoids
  a database or custom native storage code for these small non-critical settings.
  SharedPreferencesAsync uses the default Android DataStore Preferences backend
  and native iOS preferences. Platform implementations are transitive dependencies.
- main.dart injects the implementation. The UI never imports the storage plugin.
- User interactions update the UI immediately and serialize immutable snapshots
  in tap order. Queued writes continue if the screen is disposed. Failed writes
  do not break subsequent writes; a visible retry action saves the latest snapshot.
- Catalog/preferences loading completes before interactions are enabled. Read
  failures show the existing retry screen with an updated message. Missing,
  malformed JSON or wrong-shaped JSON preference payloads produce empty choices;
  non-string array values are ignored. Stale codes are filtered on load.

There is no network access, authentication, analytics or cloud synchronization.
Android identity, manifest and signing configuration are unchanged. No private
signing material is accessed by application code.

## Validation and follow-up

Unit tests exercise add/remove/deduplication, recent ordering/cap/move-to-front,
stale codes, persistence across adapter instances, and malformed storage. Widget
tests exercise empty/search-hidden sections, accessibility labels, recreation,
rotation, selection, ordering, failed-save retry and rapid queued writes after
disposal. Existing catalog/asset/search/landscape tests remain in place.

Storage tests use an in-memory implementation of the plugin API, not real device
disk. Verify cold-start persistence and immediate background/close/reopen on
physical Android and iOS devices. Like ordinary preference storage, this is not
critical transactional storage: abrupt termination during a pending write can
lose that last change. Uninstalling/clearing app data removes preferences; OS
backup/restore behavior follows platform settings. There is no account sync.

Plugin reference: https://pub.dev/packages/shared_preferences

## Validated release (2026-09-17)

- Version: 0.3.0+5; package: com.allflag.allflag.
- `dart format .`: completed. `flutter analyze`: no issues.
- `flutter test`: all 24 tests passed.
- `flutter build appbundle --release`: succeeded.
- Artifact: `build/app/outputs/bundle/release/app-release.aab`.
- Size: 50,990,713 bytes (48.63 MiB).
- Java JAR signature verification checked all 574 payload entries and matched
  the existing upload certificate SHA-256:
  `9F:61:1A:BA:E6:AC:37:EF:F0:E4:A3:73:2F:7E:E7:90:8B:75:5C:45:2D:6D:9D:AE:71:BC:74:15:89:74:36:23`.
- Android app Gradle configuration, Gradle properties and main manifest match
  their pre-task hashes. Private signing files remain ignored and untracked.
- The merged release manifest has no INTERNET permission. AndroidX contributes
  the signature-protected app-local DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION;
  this is not a user-granted runtime permission.
- No artifact was uploaded and no Play release was created.
