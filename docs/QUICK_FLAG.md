# Quick Flag — AllFlag 0.7.0+9

> v0.8 update: core features now use FlagItem/FlagId and FlagPreferences.
> Country-only persistence details below describe the original release; see
> [Generic Flag Catalog and migration](GENERIC_FLAG_CATALOG.md) for the current schema.
> User-facing behavior and device QA expectations remain unchanged.

## Purpose and choices

AllFlag is a digital flag ready for a match, parade, demonstration, recording,
or cultural event. Quick Flag shortens the path to showing the country a user
belongs to or supports. It is not a country encyclopedia.

Favorites contain many countries. Quick Flag contains zero or one country and
is independent of Favorites. Assignment never favorites or records a country
as Recent. Showing it moves that ISO code to the front of the existing five-entry,
deduplicated Recent list.

## Persistence

The existing immutable CountryPreferences snapshot adds nullable `quickFlag`.
SharedPreferencesCountryStore stores only the ISO 3166-1 alpha-2 code, under the
existing `allflag.country_preferences.v1` JSON key. Older snapshots remain valid.
Missing or wrongly typed values mean no Quick Flag; catalog validation discards
stale/unknown codes. The next normal save writes the validated snapshot.
All copies for theme, language, favorites and recent preserve Quick Flag.
The existing ordered save queue and retry message also cover Quick Flag writes.
An acknowledged local save survives restart and force close. As with other
preferences, killing the process before its asynchronous write completes can
lose the most recent tap. No network, analytics, account or cloud service is used.

## Assignment and Home

Open a country's three-dot actions menu, then choose Set as Quick Flag / Usar
como bandera rápida. Reassignment replaces the previous ISO without confirmation.
The same menu removes the current Quick Flag. The compact Home card also offers
removal in its menu. Country rows retain their Favorite action; the menu groups
Quick Flag actions rather than adding a dedicated Quick Flag toggle icon.
The current country has a textual Quick Flag subtitle, independent of color.

A compact themed card appears after the header/search, before the selected-country
message and Favorites/Recent/All Countries. It includes the flag thumbnail,
localized country name, readiness text, and an explicit Show flag action.
It remains available while searching. Without a valid Quick Flag there is no card.

## Entry, orientation and shared Flag Mode

Show flag selects the Quick Flag country, updates Recent, dismisses the keyboard,
and enters the same FlagScreen and FlagModeController used by normal rotation.
It does not push a duplicate fullscreen implementation. The image uses BoxFit.contain
on black, preserving aspect ratio and letterboxing even if rotation is unavailable.
The programmatic session requests both landscape orientations through Flutter's
public SystemChrome.setPreferredOrientations API. Ordinary physical-rotation
sessions do not request a landscape lock.

The controller serializes and coalesces transitions. Programmatic entry enables
the existing native immersive/system-bar and screen-awake implementation.
Exit requests an empty orientation list (OS defaults), never a permanent portrait
lock. System UI and ordinary sleep behavior are restored. Temporary selection is
cleared on Quick Flag exit so Home remains visible even while physically landscape.
Quick Flag assignment and Recent persist; the search query remains intact.

## Exit and accessibility decision

Only programmatic Flag Mode shows a small, safe-area, top-left close control.
It hides after four seconds; tapping anywhere on the flag reveals it again.
Its localized tooltip and semantics say Exit Flag Mode / Salir del modo bandera.
The temporary control can briefly cover a flag corner; the unobstructed view is
the default after the timeout. It has a 48-pixel minimum touch target.
With accessible navigation enabled (for example a screen reader), the control
stays discoverable instead of timing out. The flag also exposes a semantic action
to reveal controls. Android system Back exits to Home, including after timeout;
system edge gestures remain available through the existing native implementation.
iOS users use the temporary close control; the home gesture remains available.
Normal physical-rotation Flag Mode has no additional controls and returns to
Home when the device rotates back, just as before.

## Lifecycle and platform limits

Inactive, hidden, paused and detached transitions release orientation, immersive
presentation and screen-awake requests. A resumed programmatic session reapplies
them; a normal session recomputes actual orientation. Disposal queues cleanup,
including after an in-flight enable. Native pause/disconnect cleanup remains the
existing safety net. Orientation errors do not prevent display or exit; physical
rotation remains available. Immersive failures trigger best-effort cleanup.

Android phones usually honor landscape requests. Android 16/API 36 devices with
a display width of at least 600 dp may ignore orientation requests. iPad
multitasking can also ignore them. AllFlag does not disable multitasking, change
platform manifests or use private orientation APIs to override these policies.
iPhone behavior, rotation lock, OEM policies and foldable transitions need real
hardware QA. On a device that ignores the request, the same flag is immediately
shown in the current viewport and users can physically rotate it.

Reference: [Flutter setPreferredOrientations](https://api.flutter.dev/flutter/services/SystemChrome/setPreferredOrientations.html).
Android continues using the existing WindowInsetsControllerCompat host rather
than Flutter's legacy immersive mode, which target SDK 36 ignores. iOS retains
its idle timer, status-bar and home-indicator implementation. No native signing,
application ID, keystore, key.properties or release configuration changes.

## Localization and themes

All actions, readiness text, exit controls and semantic labels are English/Spanish
ARB resources. Country names are resolved from the active locale on every build:
DE remains DE when Germany becomes Alemania. System/Light/Dark use existing
BrandTokens and Material theme colors; flags remain the main color element.
No runtime dependencies were added or removed.

## Physical-device QA — pending, not claimed as executed

Run every checklist item for **Venezuela (VE), United States (US), Canada (CA),
and Japan (JP)** on Android and iOS. Record device, OS, app build, rotation-lock
setting, locale, theme and results. Automated tests do not establish real sensor,
OS gesture, native sleep or iOS build behavior.

- [ ] Set through country actions; check status text and Home card.
- [ ] Confirm assignment does not favorite or create Recent; remove a favorite
      and verify Quick Flag survives.
- [ ] Close/reopen and force-close/reopen after save; verify ISO and card.
- [ ] Tap Show flag in portrait; verify selected flag, landscape request,
      aspect ratio, black letterboxing and no stretching.
- [ ] Verify bars hide and can be revealed using system gestures.
- [ ] Leave displayed beyond the ordinary sleep timeout; verify screen awake.
- [ ] Verify exit control appears, hides after four seconds, reappears on tap,
      and returns to Home. Test Android Back after the control has hidden.
- [ ] Verify system UI, normal sleep and portrait-capable rotation return;
      repeat while still physically landscape, including rapid entry/exit.
- [ ] Background, lock/unlock, interrupt and resume; verify awake/orientation
      cleanup and correct restoration without a trapped session.
- [ ] Replace with another of the four countries; only one card remains.
- [ ] Remove via both country and card menus; restart with no card.
- [ ] English/Spanish: actions, semantic labels and translated country names.
- [ ] Light/Dark/System; change settings and verify Quick Flag identity.
- [ ] Small display, large text, TalkBack/VoiceOver, focus and touch targets.
- [ ] A: Select a normal country and physically rotate; verify the unchanged
      control-free mode and rotate-back exit, including after Quick Flag use.
- [ ] B: Enter programmatically without physically rotating; verify explicit
      exit and OS orientation restoration (distinct from A).
- [ ] Android tablet/foldable >=600 dp and iPad multitasking: ignored requests
      remain usable; physical rotation and exit work. Test rotation lock on/off.

Build validation and artifact details are recorded below after local validation.

## Validation — 2026-09-18

- Version: 0.7.0+9.
- `dart format .`: 30 files checked, zero changes in the final pass.
- `flutter analyze`: no issues found.
- `flutter test`: 125 tests passed (109 existing plus 16 Quick Flag tests).
- `flutter build appbundle --release`: passed on the final source.
- AAB: `build/app/outputs/bundle/release/app-release.aab`.
- Size: 52,017,374 bytes (49.61 MiB).
- `jarsigner -verify`: jar verified. Standard warnings: self-signed/untrusted
  public-CA chain, no timestamp (certificate expiry 2054-02-02), and unsigned
  ZIP permission/symlink metadata. These do not invalidate the matched payload.
- Independent Java JarFile signature validation read and cryptographically
  verified all 583 non-META-INF payload entries, each with exactly one signer
  matching the existing upload certificate SHA-256:
  `9F:61:1A:BA:E6:AC:37:EF:F0:E4:A3:73:2F:7E:E7:90:8B:75:5C:45:2D:6D:9D:AE:71:BC:74:15:89:74:36:23`.
- No dependencies added/removed. No upload, Play release, package-ID change,
  private signing-file edit or release-signing configuration edit.
- iOS compilation/signing and all physical-device QA above remain pending.

AAB file SHA-256: `6EEBED00BC05E208A016CCAF8B57C762BC6C77B761D275DFA99CAF99F39E89CC`.
