# AllFlag

AllFlag turns a smartphone into a digital flag. Search for a country in portrait,
select it, then rotate horizontally to display its flag without cropping or
distortion. Rotate back to choose another country.

## v0.9.0+11 release candidate

Quick Flag supports Android portrait fallback when landscape is refused. Constrained
rows provide more readable names, with localized discovery/recovery copy and stronger
automated accessibility checks. See [release readiness and physical QA](docs/RELEASE_READINESS_v0.9.md).

### Retained v0.8 foundation

- Generic FlagId, FlagItem and FlagCatalog foundation; the visible catalog remains the same 195 countries.
- Automatic, idempotent migration of Favorites, Recent and Quick Flag to namespaced IDs; theme and language are preserved.
- See [generic catalog architecture and migration](docs/FLAG_CATALOG_ARCHITECTURE.md).

- One persistent Quick Flag, independent of Favorites, with a localized Home card and Show flag action.
- Country actions assign or replace it; programmatic entry reuses Flag Mode with temporary exit controls and orientation restoration.
- See [Quick Flag architecture and physical QA checklist](docs/QUICK_FLAG.md).

- Immersive landscape Flag Mode with scoped screen-awake behavior and safe lifecycle restoration.
- See [Flag Mode architecture and physical QA checklist](docs/FLAG_MODE.md).

- English and Spanish UI and all 195 country names, with persistent System/English/Español language selection.
- AllFlag identity, independent System/Light/Dark appearance, refreshed discovery UI and branded launcher/splash assets.
- See [localization architecture and maintenance](docs/LOCALIZATION.md).
- See [visual identity and asset maintenance](docs/BRANDING.md) for tokens and screenshots.

- 195 countries: Flagpedia's complete sovereign-state list (193 UN members,
  Palestine and Vatican City), adding 190 to the original five.
- Bundled English/Spanish country names and flag PNGs: fully functional offline.
- Alphabetical, lazily built list with small decoded thumbnails.
- Persistent Favorites and up to five Recent countries, stored locally by stable generic flag ID.
- Favorites, Recent, then All Countries when search is empty; filtered catalog only during search.
- Live case- and diacritic-insensitive partial-name/ISO-code search in the active
  language; whitespace normalized, clear empty-results message, complete list for an empty query.
- Selection, search and rotation instructions preserved during orientation changes.
- Black letterboxing and native image proportions in fullscreen.
- No accounts, backend, analytics, advertising or runtime networking.

## Architecture

Immutable FlagItem and FlagId models and an asynchronous FlagCatalog boundary
serve search, selection, Favorites, Recent, Quick Flag and Flag Mode.
CountryFlagCatalog adapts the existing CountryRepository and all 195 assets and
localized names. Country-only metadata stays behind that provider boundary.
FlagPreferencesStore separates persistence from UI; SharedPreferencesFlagStore
uses one versioned JSON snapshot with automatic legacy ISO migration.
No state-management framework or new runtime dependency is introduced.

    lib/
      main.dart                       Composition root
      app.dart                        Theme and application
      domain/                         Models and repository contract
      data/local_country_repository.dart
      data/shared_preferences_flag_store.dart
      ui/home_screen.dart             Search, selection and orientation
      ui/flag_screen.dart             Proportional fullscreen image
    assets/data/countries.json        Offline 195-country metadata
    assets/flags/                    PNGs and license notice
    docs/COUNTRY_CATALOG.md           Scope and maintenance
    docs/flag-assets.json            Asset URLs, dimensions and checksums
    test/                           Domain, assets and widget behavior
    tool/update_country_catalog.ps1  Explicit development-time refresh
    android/                        Android host and existing signing pipeline
    ios/                            iOS host

See [catalog documentation](docs/COUNTRY_CATALOG.md) and
[flag license notice](assets/flags/NOTICE.md). A future remote repository can
implement the same domain contract; no remote source is implemented now.
See [Favorites and Recent persistence](docs/FAVORITES_AND_RECENT.md) for storage
format, ordering, error handling and test coverage.

## Run and validate

Use Flutter 3.47.2 stable / Dart 3.13.2 (or a compatible later toolchain).
Install the Android SDK and connect a device or start an emulator:

    flutter pub get
    flutter run

    dart format lib test
    flutter analyze
    flutter test
    flutter build appbundle --release

For iOS, macOS/Xcode and signing setup are required. Android release signing
uses the existing private configuration documented in the
[release guide](docs/GOOGLE_PLAY_RELEASE.md). Do not commit signing credentials.
The permanent package is com.allflag.allflag. v0.2.0 Internal Testing distribution
was confirmed by the owner, as was v0.4.0. v0.9.0 is not uploaded or tagged by this task.

## Limitations and follow-up

- Country scope follows the source's 195 sovereign states, excluding territories
  and other entries outside that list. Flag variants follow the source snapshot;
  Afghanistan uses the source's republic tricolor.
- Data and flags update only through a new app release. Adoption years for newly
  added countries are unresearched.
- The currently displayed selection is in-memory. Favorites and Recent persist
  across restarts; uninstalling or clearing app data removes local preferences.
- Auto-rotation and system bars remain subject to device/OS policy.
- iOS launcher and splash assets require final validation with Xcode on macOS.
- Recommended next validation: test long-list scrolling, search and rotation
  on physical Android/iOS devices, including Nepal, Switzerland and Qatar.
