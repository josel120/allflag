# AllFlag localization — v0.5.0+7

> v0.8 update: core features now use FlagItem/FlagId and FlagPreferences.
> Country-only persistence details below describe the original release; see
> [Generic Flag Catalog and migration](GENERIC_FLAG_CATALOG.md) for the current schema.
> User-facing behavior and device QA expectations remain unchanged.

## Supported locales and selection

AllFlag supports exactly English (`en`) and Spanish (`es`). The home header's
globe opens three options: **System**, **English**, **Español**. Language names
stay in their native spelling to make switching back easy. System is shown as
Sistema in Spanish. There is no separate Settings screen.

System is the default. The primary device/application locale selects Spanish
for any `es` region (including es-ES, es-MX and es-PE); all other locales, or an
absent locale, resolve to English. Explicit English or Spanish overrides the
device locale. Returning to System resumes platform locale updates immediately.
The iOS host declares English and Spanish in `CFBundleLocalizations` and English
as its development region.

## Flutter architecture

The app uses Flutter's standard `gen-l10n` pipeline with `flutter_localizations`
and `intl`, including localized Material, Cupertino and Widgets delegates.
See [Flutter internationalization](https://docs.flutter.dev/ui/internationalization).

- `l10n.yaml`: ARB input/output paths and English template.
- `lib/l10n/app_en.arb`: English UI text, placeholders and country display names.
- `lib/l10n/app_es.arb`: complete Spanish resources.
- `lib/l10n/generated/`: generated `AppLocalizations` Dart classes; do not edit.
- `lib/l10n/country_localization.dart`: display-language sorting and search.
- `lib/app.dart`: locale resolution and immediate root application updates.
- `lib/ui/`: accesses strings through `AppLocalizations.of(context)`.

Run `flutter pub get` and `flutter gen-l10n` after editing resources. Generation
also runs as part of Flutter builds because `flutter.generate` is enabled.
English is the template and fallback. Tests require equal message keys and
complete country coverage in both ARBs, preventing silent untranslated additions.
AllFlag is a brand name and is identical in both languages.

## Country names and identity

Both ARBs contain an ICU `select` message named `countryName`, indexed by the
existing uppercase ISO 3166-1 alpha-2 codes. Each has all **195** catalog entries.
English preserves the existing catalog names. Spanish uses the bundled
[Unicode CLDR 48 territory data](https://github.com/unicode-org/cldr-json/blob/48.0.0/cldr-json/cldr-localenames-full/main/es/territories.json),
with these display-name choices for this sovereign-country catalog:

- CI: Costa de Marfil
- CG: República del Congo
- PS: Palestina
- VA: Ciudad del Vaticano

The CLDR [license](UNICODE_LICENSE.txt) is bundled in the app and registered
with Flutter's license registry. Source downloads are development-time only;
localization, search, preferences and flag display work entirely offline.

`Country.code` is the stable identity. `Country.name` remains the original
English catalog metadata for compatibility; UI display uses `countryName(code)`.
Never save translated names. Favorites, recents and selection continue to refer
to ISO codes, while flag paths and flag IDs remain unchanged. Switching language
rebuilds displayed labels without changing country objects or their references.
The ICU `other` branch is an unknown-code safeguard; tests prohibit using it for
any catalog country.

## Sorting and search

All Countries and Favorites sort by the active display name, ignoring case and
vowel accents. Spanish ñ sorts as its own letter after n. Recents retain their
most-recent-first order. Sorting uses ISO code as a deterministic tie-breaker.
This is a lightweight collation rule for the two supported languages, not a
general-purpose implementation of Unicode collation.

Search normalizes the query and display name only for matching: lowercase,
Latin accent folding (including ñ to n), removal of combining marks, trim of
surrounding whitespace and collapse of internal whitespace. Matching remains
live and partial, and ISO-code matching is preserved. `peru`, `PerÚ`, `mexico`,
`panama`, and decomposed accents work; visible names keep Perú, México and Panamá.
English names are not extra aliases in Spanish search, and vice versa.
Favorites and Recent sections remain hidden while a nonempty query is active.

## Persistence and lifecycle

`LanguagePreference` has `system`, `english`, and `spanish` values, stored in the
existing `allflag.country_preferences.v1` JSON snapshot under `language`.
Missing, invalid or unknown values default to System, so existing installs need
no migration. Theme and language are independent fields. All immutable snapshot
updates preserve both, favorites and recents.

`SharedPreferencesCountryStore` continues using `SharedPreferencesAsync` native
local storage. HomeScreen queues writes in selection order and retains its
existing localized save-error/retry behavior. The root application updates
immediately, without waiting for disk I/O. Completed writes survive restart and
force close; as with any asynchronous local write, killing a process before the
write completes cannot guarantee that pending change. Rotation does not recreate
or reset preferences. Uninstalling or clearing app data removes them.

## Accessibility, layout and validation

Tooltips, favorite actions, selection feedback, errors, empty state and flag
image semantics use the active language. Normal fullscreen flag display remains
text-free with the same contain fit and black letterboxing. Header controls stack
on narrow screens or larger text scales to preserve room for the brand. Country
names and menu labels can wrap.

`test/localization_test.dart` covers complete catalog/ARB coverage, ISO uniqueness,
English/Spanish ordering and searches, locale fallback and overrides, persistence,
independent theme choices, immediate changes while storage is pending, localized
semantics, favorites/recents/selection, rotation and Spanish layouts at widths
320/375/430 with text scales 1 and 2. Existing tests remain in place.

Validate with `dart format .`, `flutter analyze`, `flutter test`, and
`flutter build appbundle --release`; verify the resulting AAB against the existing
upload certificate. No publication is part of localization work. Physical-device
force-close/TalkBack checks and iOS validation on macOS remain recommended.

## Adding another language later

1. Add `app_<language>.arb` with every English message key and all 195 country
   branches; preserve placeholder types and the brand name.
2. Extend LanguagePreference, serialization, the native-name menu resources and
   application locale resolution. Preserve current persisted enum names.
3. Declare the locale in iOS host metadata and review platform support.
4. Review that language's collation and search rules; extend normalization only
   as needed, without modifying display spellings or ISO identity.
5. Regenerate localizations and extend coverage, layout, semantics and lifecycle
   tests. Review translations and licenses before release.

This release enables only English and Spanish.

## Release validation — 2026-09-18

| Check | Result |
| --- | --- |
| Version / package | `0.5.0+7` / `com.allflag.allflag` |
| `dart format .` | Passed; 24 Dart files formatted |
| `flutter analyze` | No issues found |
| `flutter test` | 86 passed: 40 existing, 40 localization, 6 Spanish visual-preview tests |
| Country coverage | All 195 unique ISO codes have English and Spanish names |
| Spanish responsive layouts | Passed at widths 320, 375 and 430 with text scales 1 and 2 |
| `flutter build appbundle --release` | Succeeded |
| `jarsigner -verify` | `jar verified` |
| Payload verification | All 583 non-META-INF payload entries cryptographically verified against the expected upload certificate |
| AAB | `build/app/outputs/bundle/release/app-release.aab` |
| AAB size | 51,951,120 bytes (49.54 MiB) |

Upload-certificate SHA-256 (unchanged):

```text
9F:61:1A:BA:E6:AC:37:EF:F0:E4:A3:73:2F:7E:E7:90:8B:75:5C:45:2D:6D:9D:AE:71:BC:74:15:89:74:36:23
```

AAB SHA-256:

```text
387FC2C022F0274BDE574707D475D78197F96F1C2193A79C011842D70304C399
```

Jarsigner reports the existing self-signed certificate, trust-chain, missing
timestamp and POSIX-attribute warnings; payload integrity and signer identity
were independently verified. The application ID, upload keystore,
`android/key.properties` and release signing configuration were not modified.
Dependencies added: SDK `flutter_localizations` and `intl` (resolved to 0.20.3,
compatible with the SDK) for generated resources and framework localization.
No dependencies were removed.

Validation used automated tests and rendered previews. Physical-device restart,
force-close, TalkBack and iOS/macOS checks were not repeated. No Google Play
upload or release was created.
