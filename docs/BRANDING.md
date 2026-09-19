# AllFlag visual identity — v0.4.0+6

AllFlag is modern, global, simple and friendly. **Your country. Your flag.** is
the in-app tagline. **Explore the world one flag at a time.** is the secondary
marketing phrase, reserved for promotional material rather than adding clutter
to country discovery. National flags provide most of the interface's color.

## Identity and assets

The original AllFlag mark is an abstract waving flag with a simple pale pole,
blue/cyan upper ribbon and orange/pink lower ribbon on navy. It represents no
country and contains no text. The navy tile works in both themes. Keep the
silhouette, spacing and colors together; never substitute a national flag.

- `assets/branding/mark.json`: editable vector geometry and artwork colors,
  in a 108-unit coordinate space.
- `assets/branding/allflag-mark.svg`: generated scalable reference artwork.
- `assets/branding/allflag-icon.png`: generated 1024px opaque master and UI asset.
- `tool/generate_branding.ps1`: deterministic offline generator using Windows
  PowerShell/System.Drawing; no package installation or artwork download.
- `android/app/src/main/res`: generated density-specific legacy icons, adaptive
  vector foreground, launch images, day/night colors and Android 12+ splash styles.
- `ios/Runner/Assets.xcassets`: all existing iPhone/iPad/marketing icon sizes,
  launch image at 1x/2x/3x and an appearance-aware background color.

Run from the repository root after editing `mark.json`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tool/generate_branding.ps1
```

Do not hand-edit generated images or Android vector paths. Geometry is shared
across exports. The 1024px and legacy icons use 1.25x artwork magnification;
adaptive foreground geometry remains inside the central safe region to tolerate
launcher masks. PNGs are supersampled and iOS app icons have opaque navy
backgrounds with no pre-applied corner mask. iOS owns its final corner mask.
Review at 48px as well as at full size after regeneration. UI tokens and native
launch backgrounds must be kept aligned if the palette changes.

## Tokens and themes

`lib/ui/brand_theme.dart` owns `BrandTokens` and both Material 3 themes.
`AllFlagApp` persists an explicit Light or Dark preference. The header moon/sun
button switches immediately to the opposite theme with a localized action label.
Fresh installs and legacy System values resolve once from platform brightness
(dark selects Dark; otherwise Light), then ignore OS theme changes. Widgets use semantic `ColorScheme` roles and component themes.

| Token / role | Light | Dark |
| --- | --- | --- |
| Canvas | `#F7F8FA` | `#0E1624` |
| Row/search surface | `#EEF1F5` | `#1A2638` |
| Main text | `#101C30` | `#EAF0F8` |
| Secondary text/icons | `#526176` | `#AFBDD0` |
| Focus/accent | `#2364D8` | `#91B9FF` |
| Selected surface | `#E2ECFC` | `#233C60` |
| Selected foreground | `#173F7B` | `#DCE9FF` |

Artwork colors: navy `#101C30`, blue `#2364D8`, cyan `#42C9E8`, orange
`#FFAD66`, pink `#EF718C`. Warm colors are artwork accents, not text colors.
Component radius is 16 logical pixels, page padding 20, favorite controls at
least 48x48 and country rows at least 68 high. Typography inherits the platform
Material theme; country titles are 16px medium, section labels title-small and
the product name headline-medium bold. Text remains scalable.

## UI decisions and behavior

`brand_header.dart` provides the compact mark/name/tagline and designed empty
search state. `home_screen.dart` retains the existing lazy list, state, search,
favorite semantics and persistence calls. The whole discovery screen scrolls,
including its header, keeping it usable on short screens or with larger text.
The rounded search surface has a two-pixel accent focus outline and the exact
placeholder `Search countries...`. Clear search remains a working action.

Favorites, Recent and All Countries use star, history/clock and globe icons.
Empty shortcut sections remain hidden. Rows have subtle rounded surfaces with
no shadows. Thumbnails fit within 48x32 using `BoxFit.contain`; country titles
wrap without truncation. The independent favorite target uses outlined/filled
stars, accessible Add/Remove labels and toggled semantics. Selection uses both
a tinted surface and a check with a Selected semantic label. Selecting a country
still shows the rotation instruction and updates at most five recents.

`flag_screen.dart` is unchanged: selected flag only, original proportions,
black letterboxing as needed, no brand, close button or other overlay. No
special runtime handling was added for Canada or the United States; those are
only example fixture preferences in the screenshot tests.

## Native launch

Android below API 31 uses a centered static mark and day/night launch surface.
Android 12+ uses the native splash icon/background attributes, with the vector
mark on a navy icon background. Adaptive launcher icons apply from API 26;
older launchers use density-specific PNGs. No artificial delay or splash plugin.

iOS uses the existing LaunchScreen storyboard with the AllFlag image and a
named light/dark background asset. LaunchImage sizes are 144 points, with
2x/3x exports. The existing app icon catalog/configuration is retained and all
referenced PNGs replaced. Native iOS build and device launch validation require
macOS/Xcode; they were not executable on this Windows workstation.

## Validation and previews

`test/branding_test.dart` covers header/tagline, all three headings, both system
themes, empty copy, selection indicator, favorite semantics/touch targets and
fullscreen behavior. It exercises all four requested long names at widths
320/375/430 with text scales 100%/200%. Existing catalog, persistence, search,
recent ordering and rotation tests remain in place unchanged.

Widget-rendered previews (not physical-device screenshots):

- [Light home](screenshots/home-light.png) / [dark home](screenshots/home-dark.png)
- [Light selection](screenshots/selected-light.png) / [dark selection](screenshots/selected-dark.png)
- [Light empty search](screenshots/empty-light.png) / [dark empty search](screenshots/empty-dark.png)
- [Landscape](screenshots/landscape-light.png)
- [320px phone with 200% text, scrolled](screenshots/small-phone-large-text.png)

To regenerate previews, point `ALLFLAG_FONT_DIR` at the Flutter SDK's
`bin/cache/artifacts/material_fonts` directory:

```powershell
flutter test test/branding_test.dart --dart-define=ALLFLAG_CAPTURE=true --dart-define=ALLFLAG_FONT_DIR=C:/flutter/bin/cache/artifacts/material_fonts
```

The optional capture path loads local SDK fonts and waits for visible images to
decode. Normal tests require no external font path and write no screenshots.
Native launcher masks, status bars, OS splash presentation and physical-device
rotation should still be checked on Android and iOS. No dependencies were added
or removed. No catalog records, application ID or signing configuration changed.

### Release validation

- `dart format .`: passed (18 Dart files).
- `flutter analyze`: no issues.
- `flutter test`: 32 passed, including all 24 original tests and 8 new tests.
- `flutter build appbundle --release`: succeeded for 0.4.0+6.
- `jarsigner -verify`: `jar verified`; expected self-signed upload-certificate
  trust/timestamp warnings do not indicate a signature mismatch.
- The AAB signer SHA-256 matches the existing owner-confirmed upload certificate:
  `9F:61:1A:BA:E6:AC:37:EF:F0:E4:A3:73:2F:7E:E7:90:8B:75:5C:45:2D:6D:9D:AE:71:BC:74:15:89:74:36:23`.
- Before/after hashes of the keystore, `android/key.properties` and
  `android/app/build.gradle.kts` match. Application ID remains `com.allflag.allflag`.
- Output: `build/app/outputs/bundle/release/app-release.aab`.
  Size: 51,003,474 bytes (48.64 MiB). The merged release manifest confirms
  versionName `0.4.0`, versionCode `6` and package `com.allflag.allflag`.
- Nothing was uploaded and no Google Play release was created.
