# Immersive Flag Mode — AllFlag v0.6.0+8

> v0.8 update: core features now use FlagItem/FlagId and FlagPreferences.
> Country-only persistence details below describe the original release; see
> [Generic Flag Catalog and migration](GENERIC_FLAG_CATALOG.md) for the current schema.
> User-facing behavior and device QA expectations remain unchanged.

## Activation and exit

Select a country, then rotate to landscape. Flag Mode is shown only when a
country is selected and the Flutter viewport is landscape. Without a selection,
landscape retains the normal country browser. Portrait always returns to the
normal AllFlag interface. There is no fullscreen button, close button, hidden
exit gesture, branding, country-name overlay or other controls on a normal flag.
System navigation remains available.

Selection and search remain in HomeScreen's state. Favorites, the five most
recent ISO codes, appearance and language preferences use their existing storage
unchanged. Entering/exiting Flag Mode does not write preferences or add another
Recent entry. Selection itself remains in-memory as before, not restored after
process termination. No portrait redesign or new translated copy is included.

## Architecture

- `lib/ui/home_screen.dart` computes presentation from selection and orientation.
  It coalesces post-frame platform synchronization and observes app lifecycle.
- `lib/ui/flag_mode_controller.dart` enables platform effects only when presenting
  a flag **and resumed**. It deduplicates requests, serializes async calls, skips
  superseded queued work and restores normal state after disposal or an error.
- `lib/platform/flag_mode_platform.dart` is the injectable platform boundary.
  Its mobile method channel is `com.allflag.allflag/flag_mode`, with one boolean
  `setFlagMode` request controlling the screen-awake/presentation transition.
- `lib/ui/flag_screen.dart` remains a black, full-size, contain-fit local image.
- `android/.../MainActivity.kt` owns Android window insets and screen-awake flags.
- `ios/Runner/AppDelegate.swift` registers the idle-timer channel through the
  implicit Flutter engine; `SceneDelegate.swift` provides native cleanup.

The adapter uses the actual operating system, independent of Flutter's theme
platform setting. Nonmobile hosts use only Flutter's overlay path, which also
allows existing desktop-hosted widget tests to run without native mobile code.
Only Android and iOS are supported app targets.

## Android system UI and screen awake

The app continues targeting the SDK selected by Flutter (currently API 36).
Flutter documents that its legacy non-edge-to-edge `SystemUiMode` values are
ignored with this target. This implementation therefore uses
`WindowCompat.getInsetsController`, `WindowInsetsControllerCompat.hide/show`
and `WindowInsetsCompat.Type.systemBars()` in the Android host. It does not opt
out of edge-to-edge or change the release build configuration.

`BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE` allows the OS to reveal status/navigation
bars on an edge swipe, then hide them according to platform policy. There is no
gesture interception, navigation blocking, hide-on-every-frame loop, or timer
that fights a user's revealed system bars. Returning to portrait shows the bars
and restores default bar behavior while retaining normal edge-to-edge layout.

Only active Flag Mode sets the activity window's `FLAG_KEEP_SCREEN_ON`. Exit,
loss of foreground/focus and destruction clear it. This is a foreground screen
flag, not a CPU wake lock, background service, permission or brightness change.
Native checks additionally require a resumed/focused activity and landscape
configuration, so delayed Dart requests cannot enable it in a background or
portrait activity. After Flutter's native resume hook restores its overlay
defaults, the host reapplies the current eligible presentation once.

AndroidX Core is already provided by the Flutter embedding; no new package or
Gradle dependency is needed. Its compatibility layer uses the modern insets API
on current Android and the platform-supported fallback on older Android.

References: [Android immersive mode](https://developer.android.com/develop/ui/views/layout/immersive),
[keeping the screen on](https://developer.android.com/develop/background-work/background-tasks/awake/screen-on),
and [Flutter SystemChrome constraints](https://api.flutter.dev/flutter/services/SystemChrome/setEnabledSystemUIMode.html).

## iOS behavior

Flutter's supported `SystemUiMode.immersiveSticky` requests a hidden status bar
and auto-hidden home indicator; `edgeToEdge` restores them on exit. iOS controls
the final visibility and gesture behavior. No private API, forced orientation,
gesture deferral or custom view-controller workaround is used.

The native channel scopes `UIApplication.shared.isIdleTimerDisabled` to active
Flag Mode while `applicationState` is active. It is reset on normal exit, scene
resignation, backgrounding, scene disconnection and application termination.
The Dart lifecycle controller restores overlays and reevaluates the mode on
resume. Registration uses `FlutterImplicitEngineBridge.applicationRegistrar`
to remain compatible with this project's existing UIScene lifecycle.

References: [Flutter system UI modes](https://api.flutter.dev/flutter/services/SystemUiMode.html),
[Apple idle timer](https://developer.apple.com/documentation/uikit/uiapplication/isidletimerdisabled),
and [Flutter platform channels](https://docs.flutter.dev/platform-integration/platform-channels).

## Lifecycle and restoration

1. A selected country and landscape viewport request Flag Mode after layout.
2. Only `AppLifecycleState.resumed` permits immersive/awake effects.
3. Inactive, hidden, paused or detached states release those effects immediately
   through the controller; native lifecycle cleanup also protects the screen timer.
4. Resume schedules a frame before deciding whether to re-enable, allowing a
   background orientation change to take effect first.
5. Disposal queues a final normal-state request even if entry is still in flight.
6. Ordinary rebuilds, localized labels, theme updates and system inset changes
   do not repeatedly configure the platform while the desired state is unchanged.

If a platform request fails, the controller attempts to restore normal state,
logs the failure and does not spin on repeated rebuilds. A later mode/lifecycle
transition can retry. Platform failures do not change the selected country or
persisted preferences.

## Orientation, appearance and performance

Both landscape directions remain supported by existing host configuration.
There are no `setPreferredOrientations` calls or changes to device orientation
settings. The operating system's rotation lock and windowing policies still apply.

`BoxFit.contain` preserves the actual decoded asset's proportions. The canvas
is black in every theme; flag pixels receive no tint, scale distortion or crop.
US and Canada preserve their respective source ratios, Switzerland stays square,
and Nepal's nonrectangular artwork remains intact within its source canvas.
Unused viewport area is black. No SafeArea adds portrait-style padding to the
flag, and lingering keyboard insets cannot shrink its canvas.

There is no entry/exit animation, network access or image regeneration. The
existing Flutter AssetImage/ImageCache path reuses the selected flag across
rebuilds and rotations while cached. Normal memory pressure can evict images;
later access then decodes the bundled asset again. Brightness is never changed,
persisted or permission-gated.

## Automated coverage

Existing tests are retained. `test/flag_mode_controller_test.dart` exercises
deduplication, every lifecycle state, coalescing, async disposal races, failure
cleanup and Android/iOS channel routing. `test/flag_mode_test.dart` covers entry
conditions, restoration, repeated rotations, all preference preservation,
no-controls presentation, all themes, background rotation, disposal, cache reuse,
and rendered-image fit for US/CA/CH/NP (including the square and Nepal cases).

Widget and channel tests do not prove actual OS bar visibility, auto-lock timing
or hardware rotation. The physical checks below are required before approval.

## Known platform limits

- Android transient bars, gesture hints, OEM behavior, accessibility services and
  system dialogs can temporarily reveal overlays. They must remain recoverable.
- Android desktop/multiwindow mode may retain a system caption bar. Cutouts and
  system-reserved regions are controlled by the OS; inspect real device layouts.
- Android may temporarily prevent hiding navigation after keyboard dismissal,
  especially on older versions. Check fast search/select/rotate and selecting
  while already landscape. Do not defeat the platform's navigation safeguards.
- iOS treats home-indicator hiding as a preference, not a permanent guarantee.
  Calls, Control Center, lock/unlock and multitasking may interrupt presentation.
- Auto-rotation lock may prevent the primary rotate-to-enter/exit interaction;
  normal system navigation still works. Large-screen window resizing can also
  change the viewport orientation.
- Screen-awake avoids automatic idle sleep, not explicit user lock, battery
  shutdown or other OS policy. Keeping a display on consumes additional power.
- iOS native build and device validation require macOS/Xcode and were not run
  in this Windows workspace. A physical Android check is also still required.

## Physical-device QA checklist

Record device model, OS version, navigation mode, rotation-lock state and tester.
Use an Android API 36 device with gesture navigation, a three-button navigation
configuration, an older supported Android device when available, and an iPhone
with a home indicator. Include an iPad if supported for distribution. Set a short
normal auto-lock timeout and start with auto-rotation enabled. Restore the
tester's timeout/navigation settings after QA.

For **each** row below, check **both landscape left and landscape right**:

| Country | Proportions / unused space | Left | Right | Bars / gestures | Awake past idle timeout | Portrait restore | Repeat 5 times |
| --- | --- | --- | --- | --- | --- | --- | --- |
| United States | Source ratio about 1.9:1; black unused space | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Canada | Source ratio 2:1; black unused space | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Switzerland | Square artwork; black side areas on a wide screen | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Nepal | Original nonrectangular artwork, no stretching; black unused space | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

For every flag/direction:

- [ ] Select in portrait and rotate: only the flag appears, without animation,
  name, logo, instructions, close button or language/theme controls.
- [ ] Check status/navigation bars hide where supported. Swipe to reveal system
  navigation; confirm it works and any transient bars follow normal OS behavior.
- [ ] Check the entire artwork is visible, untinted and proportionally correct,
  including near cutouts and the gesture-navigation area.
- [ ] Leave untouched beyond the normal idle timeout: display stays awake.
- [ ] Return to portrait: normal bars/interface reappear, selected country and
  search remain, and the display can sleep normally after the idle timeout.
- [ ] Repeat rotations at least five times, including landscape-to-landscape.

Lifecycle, settings and user control:

- [ ] Repeat representative flags in Light, Dark and System, and English/Spanish.
  Flag Mode remains black; portrait restores the chosen theme and language.
- [ ] Favorite a country and create several recents; enter/exit repeatedly and
  confirm favorites are unchanged and recents are neither duplicated nor reordered.
- [ ] With no selection, rotate: country browser remains visible and can sleep.
- [ ] Search/select/rotate quickly with the keyboard closing; also select while
  already landscape. Confirm no keyboard or permanent bars obscure the flag.
- [ ] Background in Flag Mode via system navigation: awake state is released.
  Return still landscape: immersive/awake behavior returns appropriately.
- [ ] Background in Flag Mode, rotate to portrait, then return: normal interface
  and sleep behavior return without stale immersive state.
- [ ] Open notifications/Control Center or another interruption and dismiss it.
  Ensure navigation remains available and Flag Mode resumes appropriately.
- [ ] Lock manually in Flag Mode, unlock, and repeat with a rotation while locked.
  The app must never prevent locking/unlocking or force the display to turn on.
- [ ] Exit/back/home from Flag Mode, reopen and verify no leaked hidden bars or
  screen-awake state in portrait. Force-close and relaunch as an additional check.
- [ ] Confirm device brightness never changes during these transitions.

Do not upload or create a Google Play release as part of this checklist.

## Release validation — 2026-09-18

| Check | Result |
| --- | --- |
| Version / application ID | `0.6.0+8` / `com.allflag.allflag` |
| `dart format .` | Passed; 29 Dart files, no remaining formatting changes |
| `flutter analyze` | No issues found |
| `flutter test` | 109 passed: all 86 existing tests plus 23 Flag Mode tests |
| `flutter build appbundle --release` | Succeeded, including native Android compilation |
| `jarsigner -verify` | `jar verified` |
| Independent payload verification | All 583 non-META-INF entries verified against the existing upload certificate |
| Output | `build/app/outputs/bundle/release/app-release.aab` |
| Size | 51,957,760 bytes (49.55 MiB) |
| New/removed dependencies | None |
| Signing safety | Keystore, `android/key.properties` and `android/app/build.gradle.kts` SHA-256 values match their pre-change values |

Existing upload certificate SHA-256:

```text
9F:61:1A:BA:E6:AC:37:EF:F0:E4:A3:73:2F:7E:E7:90:8B:75:5C:45:2D:6D:9D:AE:71:BC:74:15:89:74:36:23
```

AAB SHA-256:

```text
952E91408B47EFB5257BB9276058CBDDE3FD79D0FAEA77363CFEC0E14F6B54FC
```

Jarsigner's expected self-signed/trust-chain, timestamp and POSIX-attribute
warnings remain; they do not change the verified payload integrity or certificate
match. No credentials were printed or changed. No wake-lock or brightness
permission was added. No Google Play upload or release was created.

Physical-device checks above remain **pending**, including both landscape
directions, native system-bar behavior, actual idle timeout, interruptions and
lock/unlock. iOS native compilation/device behavior also needs macOS/Xcode QA.
