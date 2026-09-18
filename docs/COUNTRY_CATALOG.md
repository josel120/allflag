# Offline country catalog — v0.2.0

The app bundles all 195 entries in Flagpedia's sovereign-state list: 193 United
Nations members plus Palestine and Vatican City. This adds 190 countries to the
five-country v0.1 catalog. This scope intentionally excludes dependent
territories, subnational flags and the source's other country-like entities.

Scope source: https://flagpedia.net/sovereign-states
Flag source: https://flagcdn.com/w2560/{lowercase-code}.png
License statement: https://flagpedia.net/terms (public-domain flag images)

## Data and display

assets/data/countries.json is a bundled snapshot of the country code, English
display name and current flag metadata. Codes are ISO 3166-1 alpha-2; every
entry has exactly one bundled current flag. Country selection and the JSON
repository use the existing CountryRepository boundary. No HTTP client or
runtime network access is involved.

Country names follow the source's English sovereign-state list, with two
unaccented English display names: Ivory Coast and Sao Tome and Principe. The
repository sorts names case-insensitively; the JSON is also alphabetized.
Search matches name substrings and country codes, ignoring case and surrounding
query whitespace. Empty queries restore the complete list.

Adoption years are preserved for the original five entries. Other startYear
values are null (unknown), not fabricated. IDs for the original five flags are
unchanged. New IDs use the stable country code plus '-current'; any later
historical-data release must review design identifiers and adoption periods.

The list creates rows on demand and decodes thumbnails to their display width.
Fullscreen uses the original 2560px-wide PNG with BoxFit.contain, retaining
native proportions and transparency, including square flags and Nepal's shape.
No orientation/system-UI behavior or Android signing configuration was changed.

## Source snapshot and maintenance

docs/flag-assets.json records the retrieval date, each asset URL, PNG width and
height, and SHA-256 checksum. The source's conventions are retained, including
Afghanistan's republic tricolor as served by FlagCDN, Syria's green/white/black
three-star design, and Venezuela/Peru's civil national variants. This release
does not independently reinterpret disputed recognition or flag variants.

To refresh deliberately from a development machine with network access:

```powershell
./tool/update_country_catalog.ps1
dart format lib test
flutter analyze
flutter test
```

The maintenance script refuses a source list other than 195 entries. Review any
source changes, names, flags and checksums before accepting a refresh. It is not
bundled or executed by the app. A source update requires a new app release;
there is no automatic metadata or asset download.

## Validation and limitations

Tests compare the complete code set against an independent 195-code fixture,
verify uniqueness, nonempty names, sorting, immutability, decode every bundled
flag, and check representative aspect ratios. Widget tests cover case/partial/
whitespace search, multiple matches, empty results, lazy scrolling to Zimbabwe,
selection retention, landscape and load retry.

The existing Android release pipeline is retained. v0.1.2 distribution through
Google Play Internal Testing was confirmed by the owner; v0.2.0 is not uploaded.
Recommended follow-up is physical-device verification of long-list scrolling,
search, rotation and representative square/nonrectangular flags. iOS validation
still requires macOS/Xcode. Accent-insensitive search and alternate country-name
aliases are outside this release's requirements.

## v0.2.0 validation result

- Version: 0.2.0+4.
- dart format lib test: passed.
- flutter analyze: no issues.
- flutter test: all 12 tests passed.
- flutter build appbundle --release: passed using the existing signing setup.
- Output: build/app/outputs/bundle/release/app-release.aab, 50,247,122 bytes
  (approximately 47.92 MiB).
- AAB signature verified across all 276 payload entries and matched the existing
  upload certificate. No signing configuration or private file was modified.
- Android app Gradle configuration, Gradle properties and main manifest hashes
  match their pre-task baseline; the package identity is unchanged.
- No Google Play upload or release creation was performed.
