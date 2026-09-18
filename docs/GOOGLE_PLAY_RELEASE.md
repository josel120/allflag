# AllFlag Android release readiness — v0.1.2 upload signing

## Final Phase B verification — successful

AllFlag 0.1.2+3 now builds and signs successfully. The owner resolved the remaining
store-authentication issue locally by changing the JKS store password and
updating the private configuration. The upload certificate is unchanged. The
agent did not modify the keystore or passwords. Earlier blocked attempts below
are historical and superseded by this result.

| Check | Final result |
| --- | --- |
| flutter build appbundle --release | Passed |
| flutter build apk --release | Passed |
| APK apksigner verification | Passed; one signer, APK Signature Scheme v2 |
| AAB jarsigner verification | Passed: jar verified |
| AAB payload verification | All 85 non-META-INF payload entries cryptographically verified against the expected certificate |
| flutter analyze | No issues |
| flutter test | All 7 tests passed |
| Version / package | 0.1.2+3 / com.allflag.allflag |

Both artifacts use this exact upload certificate SHA-256:

```text
9F:61:1A:BA:E6:AC:37:EF:F0:E4:A3:73:2F:7E:E7:90:8B:75:5C:45:2D:6D:9D:AE:71:BC:74:15:89:74:36:23
```

Final AAB: build/app/outputs/bundle/release/app-release.aab — 47,665,881 bytes
(approximately 45.46 MiB). Final APK:
build/app/outputs/flutter-apk/app-release.apk — 48,219,031 bytes
(approximately 45.99 MiB). Both files exist.

jarsigner reports a self-signed certificate/untrusted public-CA chain, no
timestamp, and unsigned ZIP permission/symlink attributes. These warnings are
recorded separately from the successful cryptographic signature validation;
the expected upload certificate was explicitly matched. Its reported expiry
is 2054-02-02. APK v2 verification succeeded for this minSdk 24 application.

Git safety: android/key.properties and android/keystore/allflag-upload-key.jks
remain ignored and untracked. A local in-memory check found no configured
password values in either of the 2 indexed files or 84 Git-visible working
files. The public example contains blank password fields. No credentials were
printed, copied into reports or committed. Existing example staging was left
unchanged. No upload was performed.

Local upload-signing verification is complete. Remaining manual work includes
Play App Signing enrollment if prompted, creating the internal release and
uploading the signed AAB, plus final signed-device testing. Store listing and
policy tasks below remain unconfirmed.

## Phase A status

The owner has approved com.allflag.allflag permanently for both applicationId
and namespace, and confirmed Play Console app creation and Internal Testing
tester configuration. Neither identity value was changed.

The owner created android/keystore/allflag-upload-key.jks and configured
android/key.properties locally, then explicitly authorized Phase B. Both files
exist, are ignored by Git, and are untracked. The agent did not generate the key
or passwords. The commands below are setup reference only; do not regenerate
the existing key.

Run these commands yourself in PowerShell from the project root. The installed
JDK executable and its supported options were checked locally. Explicit JKS
format avoids relying on the JDK default store format.

```powershell
New-Item -ItemType Directory -Force android/keystore | Out-Null
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v -storetype JKS -keystore "android/keystore/allflag-upload-key.jks" -alias allflag-upload -keyalg RSA -keysize 2048 -validity 10000
```

Enter passwords and certificate identity details at the interactive prompts.
Pressing Enter at the key-password prompt reuses the store password; otherwise
record the separate key password. Do not repeat generation if the key exists.

```powershell
if (-not (Test-Path android/key.properties)) {
    Copy-Item android/key.properties.example android/key.properties
}
notepad android/key.properties
```

Fill the blank passwords locally, preserving this structure:

```properties
storeFile=keystore/allflag-upload-key.jks
storePassword=<ENTER_LOCALLY>
keyAlias=allflag-upload
keyPassword=<ENTER_LOCALLY>
```

Never send passwords or file contents in chat. Relative paths resolve from
android/, not android/app/. Java properties interpret backslash escapes: double
any literal backslashes in passwords; do not wrap values in quote delimiters.
Keep both passwords exactly consistent with those entered in keytool.

Back up the upload keystore and passwords securely outside the repository, using
access-controlled encrypted storage and a password manager. Never commit them
as a backup. Losing the upload key can require an upload-key reset with Google
Play; it is separate from the final app signing key managed by Google.
This workspace is under OneDrive; apply your intended private-key sync controls
to the local keystore directory.

The Phase A stop was satisfied by the owner's confirmation and Phase B
authorization. No upload is authorized or performed.

Audit date: 2026-09-17. No artifacts were uploaded and no Play Console actions
were performed. This is a release engineering audit, not a feature release.

## Android configuration

| Item | Value |
| --- | --- |
| Application label | AllFlag |
| applicationId | com.allflag.allflag (permanent; owner approved) |
| namespace | com.allflag.allflag |
| versionName / versionCode | 0.1.2 / 3 |
| minSdk / targetSdk / compileSdk | 24 / 36 / 36 |
| Flutter / Dart | 3.47.2 stable / 3.13.2 |
| Android Gradle Plugin / Gradle | 9.1.0 / 9.3.1 |
| NDK | 28.2.13676358 |

SDK values come from the installed Flutter Gradle extension; no speculative SDK
upgrade or hardcoded override was introduced. Recheck these values after any
Flutter upgrade. The previous version was 0.1.1+2. The signing release increment
uses pubspec.yaml; Gradle reads flutter.versionName and flutter.versionCode.
Increment the build number for each new Play upload. Do not manually edit the
generated android/local.properties version values.

The owner approved the existing package as permanent. No identity change was
made. Package identity is effectively permanent once published.

## Current policy verification

Google's [target API policy](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)
was checked on the audit date: new phone apps and updates require API 36 or
higher from August 31, 2026. AllFlag targets 36 and satisfies that requirement.

Flutter bundles native libraries. Follow Android's
[16 KB page-size guidance](https://developer.android.com/guide/practices/page-sizes)
and validate the final signed artifact on a 16 KB device/emulator. The project
already uses AGP newer than 8.5.1 and NDK r28; no toolchain upgrade was needed.

## Permissions and orientation

The main manifest requests no permissions. Debug/profile manifests request only
android.permission.INTERNET for Flutter debugging and service communication;
these variants are not merged into release. No networking permission was added.
The PROCESS_TEXT queries entry is package visibility metadata, not a permission.

The merged release manifest adds exactly one requested permission:
com.allflag.allflag.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION, defined with
signature protection by androidx.core:core:1.13.1. It protects internal dynamic
receivers and is retained. There are no requested Android platform permissions.
The profile installer receiver is protected by android.permission.DUMP; that
attribute restricts its callers and does not request DUMP for AllFlag.

No screenOrientation lock is declared. The existing orientation configChanges
handling, Flutter MediaQuery switch, BoxFit.contain, black background, and
immersiveSticky request are unchanged. Android can still impose system-bar
behavior. The owner confirmed v0.1 physical Android validation; this does not
substitute for installing the final signed v0.1.2 release.

## Signing strategy and private setup

The initial template signed release with the debug key. That fallback has been
removed. In v0.1.2, release tasks fail clearly without android/key.properties.
There is no unsigned-release fallback. Debug development can continue without
the private file. The upload keystore was created privately by the owner.

With a complete key.properties file, Gradle uses the release signing config.
An incomplete file or missing keystore fails configuration instead of falling
back to debug signing. Final Phase B verified both signed artifacts against the
expected upload certificate; see the successful result above.

Human setup, when ready:

1. Keep the approved permanent package identifier unchanged.
2. Create or obtain a dedicated upload keystore privately using the official
   [Flutter Android signing guide](https://docs.flutter.dev/deployment/android#sign-the-app).
   Use the ignored android/keystore/ location and a secure external backup.
   Do not place passwords on command lines or in chat.
3. Copy android/key.properties.example to android/key.properties locally.
   Fill storeFile, storePassword, keyAlias and keyPassword using a private editor.
   On Windows use forward slashes in the absolute storeFile path. Relative paths
   resolve from android/, not android/app/.
4. Verify git check-ignore covers the private files before staging changes.
5. Re-run the build commands below and verify the signing certificate. Use
   jarsigner -verify on the AAB and Android build-tools apksigner verify on APK.
   Compare the public upload certificate fingerprint with the expected key.
6. In Play Console, enroll in Google Play App Signing: Google manages the app
   signing key; the developer retains the upload key used for AAB submissions.
   Complete this manually only when authorized to proceed.

Never commit keystores (.jks/.keystore/.p12/.pfx), real key.properties, passwords,
private keys, service-account credentials or Play credentials. Existing Android
ignore rules and repository-wide keystore/key.properties rules cover the common
signing files. Alternate filenames still require explicit ignore rules. The
tracked example contains only blank fields and instructions.

## Reproducible validation and builds

From the project root, with the audited Flutter and Android SDK installed:

```powershell
flutter clean
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

Stop and resolve any failing command before considering a release ready.
Expected APK: build/app/outputs/flutter-apk/app-release.apk.
Expected AAB: build/app/outputs/bundle/release/app-release.aab.
Run these commands in Phase B only after the private signing file is configured.
Never upload an unsigned audit build left over from v0.1.1.

## Google Play Readiness

- [x] Permanent applicationId selected and owner-approved
- [x] Application name verified
- [x] Versioning configured
- [x] Current target API requirement verified
- [x] Permissions audited in the generated release APK and merged manifest
- [x] Release signing strategy and safe configuration structure prepared
- [x] Private upload key configured and signing verified
- [x] Release APK builds and signature verifies
- [x] Release AAB builds and signature verifies
- [x] Physical Android test completed for v0.1 (confirmed by owner)
- [ ] Final signed v0.1.2 physical Android test completed
- [ ] 16 KB runtime validation completed
- [x] Play Console application created (owner confirmed)
- [x] Internal Testing testers configured (owner confirmed)
- [ ] App signing configured in Play Console
- [ ] Store listing prepared
- [ ] App icon prepared (current Flutter template icon is a placeholder)
- [ ] Feature graphic prepared
- [ ] Screenshots prepared
- [ ] Data Safety completed
- [ ] Content rating completed
- [x] Privacy policy requirement evaluated
- [ ] Privacy policy published and accessible in the app
- [ ] Internal testing release created
- [ ] Production-access requirements checked for the actual account

## Remaining manual Play Console work

With app creation and identity confirmed, configure Play App
Signing, supply an upload key and rebuild. Prepare the listing, contact details,
icon, feature graphic, screenshots, target audience, ads declaration (no ads),
app access declaration (no restricted access) and content rating questionnaire.

The current app has no analytics, accounts, networking, or third-party runtime
plugins. Review that behavior when completing Data Safety; the form has not
been submitted. Google's [User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en-GB)
requires a public privacy policy and in-app access even when no personal data is
collected. Prepare truthful owner/contact details, host the policy and add its
in-app access in a separately scoped change; no UI feature was added here.

After signed-artifact checks, use the configured internal testers and prepare release
notes and create an internal testing release when authorized. Internal testing
is not production access. For newer personal accounts, Google's
[testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)
include a closed test with at least 12 continuously opted-in testers for 14 days
before applying for production access. Account type/date and account-specific
requirements have not been checked. Do not mark any Console task complete based
solely on this repository audit.

## Historical v0.1.1 build and artifact inspection results

These are previous unsigned-build results, not v0.1.2 signing validation.

- flutter clean and flutter pub get succeeded. Pub reported three newer packages
  outside current constraints; no dependencies were added or upgraded.
- dart format .: 10 files checked, zero changes.
- flutter analyze: no issues.
- flutter test: all 7 existing tests passed, unchanged.
- flutter build apk --release: succeeded (202.2 seconds).
  build/app/outputs/flutter-apk/app-release.apk exists, 48,210,839 bytes
  (approximately 46.0 MiB); Gradle also names its original app-release-unsigned.apk.
- flutter build appbundle --release: succeeded (32.0 seconds).
  build/app/outputs/bundle/release/app-release.aab exists, 47,659,141 bytes
  (approximately 45.5 MiB).
- Both archives contain arm64-v8a, armeabi-v7a and x86_64, with libapp.so and
  libflutter.so for each. No ABIs were removed.
- aapt dump badging on the APK confirms package com.allflag.allflag, label
  AllFlag, versionName 0.1.1, versionCode 2, min SDK 24, target/compile SDK 36,
  and the single AndroidX signature permission described above. No debuggable
  flag or orientation lock appears in the release manifest.
- apksigner verification fails as expected for the deliberately unsigned APK
  (Missing META-INF/MANIFEST.MF). jarsigner identifies the AAB as unsigned.
  This is the principal artifact blocker: neither file is ready for Play upload.
- Runtime dependency metadata uses flutter_embedding_release and the three
  release engine ABI artifacts, plus standard Kotlin/AndroidX transitive
  libraries. No debug embedding or Dart test/lint runtime dependency was found.
- Bundled app assets are the five flag PNGs and their 1.3 KB license notice,
  standard Flutter manifests/license notices, two Flutter shaders and a
  tree-shaken Material icon font. No obvious unnecessary large assets were found.
  Icon tree-shaking reduced the font to 1,660 bytes; this was informational.
- Android zipalign -c -P 16 4 on the APK returned zero. llvm-readelf inspection
  of both native libraries for arm64-v8a and x86_64 shows 0x10000 LOAD alignment;
  GNU_RELRO end addresses are 16 KB aligned. These static checks passed but do
  not establish runtime compatibility on a 16 KB device.
- AAB archive inspection confirmed its base manifest, BundleConfig.pb and all
  three ABI payloads. A standalone bundletool validation/Play pre-launch report
  was not run. Repeat artifact inspection after supplying the upload key.
- No release compilation errors or SDK incompatibilities were reported. Signed
  build/install, Play acceptance and final-device behavior remain unverified.

Inspection commands (substitute your Android SDK and JDK paths):

```powershell
aapt dump badging build/app/outputs/flutter-apk/app-release.apk
zipalign -c -P 16 4 build/app/outputs/flutter-apk/app-release.apk
apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk
jarsigner -verify build/app/outputs/bundle/release/app-release.aab
Get-Item build/app/outputs/bundle/release/app-release.aab
```

Signing verification must succeed for the final signed release. The audit
failure above is not a successful signing check.

## Next manual step after successful Phase B

Google Play Console → Internal Testing → Create new release → configure/accept
Play App Signing if prompted → upload the signed AAB.

The agent will not perform the upload. Play App Signing enrollment and the
internal testing release have not been confirmed complete.

## Earlier v0.1.2 Phase B result — blocked

Version is now 0.1.2+3. Application ID and namespace remain com.allflag.allflag.
No app behavior, dependencies or private credentials were changed.

- flutter clean and flutter pub get: passed.
- dart format .: 10 files, no changes.
- flutter analyze: no issues.
- flutter test: all 7 tests passed.
- flutter build apk --release: failed at :app:packageRelease.
- flutter build appbundle --release: failed at :app:signReleaseBundle.
- Both signing failures report: "Keystore was tampered with, or password was incorrect".
- Independent JDK keystore loading also failed. No certificate fingerprint is
  reported because the upload certificate could not be authenticated.
- No final APK or AAB exists at the expected paths after the clean build.
  AAB size is unavailable. Intermediate files are not releases.
- Private files are ignored and untracked. The public example is indexed with
  blank password fields. An in-memory check found no configured password values
  in 83 Git-visible working files or either of the 2 indexed files. No passwords
  or private file contents were printed or copied into reports.
- No commit or upload occurred. Existing example staging was left unchanged.
  No debug-signing or unsigned-release fallback was used.

### Human correction required

Do not regenerate or overwrite the keystore. Test it interactively from the
project root using the password originally entered during key creation:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -keystore "android/keystore/allflag-upload-key.jks" -alias allflag-upload -storetype JKS
```

This prompts locally; do not supply password arguments or send passwords in
chat. If it opens, correct storePassword in android/key.properties privately.
Confirm keyPassword matches the key password used during creation, often the
same as the store password. Java properties process backslash escapes: double
literal backslashes, avoid quote delimiters and unintended trailing spaces.

If keytool also fails with the original password, verify the intended keystore
and secure backup. The message alone cannot distinguish a wrong password from
corruption. Confirm corrected local configuration before retrying Phase B.
Signature verification, public certificate comparison, Play App Signing setup,
the internal release and signed-device testing remain pending.

### Retry after human keystore verification

The owner confirmed keytool can open the keystore, alias allflag-upload is a
PrivateKeyEntry, and supplied this public certificate SHA-256:

```text
9F:61:1A:BA:E6:AC:37:EF:F0:E4:A3:73:2F:7E:E7:90:8B:75:5C:45:2D:6D:9D:AE:71:BC:74:15:89:74:36:23
```

This is a human-verified reference, not a fingerprint verified from a generated
artifact. The subsequent clean retry again passed formatting, analysis and all
7 tests, but both APK and AAB signing failed with the same password/integrity
error (packageRelease and signReleaseBundle respectively). Neither expected
final artifact exists, so no artifact size or verified signature is available. Private
configuration and keystore contents were not inspected during this retry; only
Gradle used them for the authorized signing attempt. No passwords were scanned
or read by a diagnostic helper in this retry.

Because interactive keytool succeeds, reconcile the password entered there with
the value Java Properties supplies to Gradle. Check locally for literal quotes,
unintended trailing spaces, duplicate property assignments, and unescaped
backslashes. In Java properties, dollar signs need no special escaping; literal
backslashes do. Do not paste credentials into shell commands or chat, and do
not regenerate the key. The file must be saved at android/key.properties.

## Historical properties-loading investigation (resolved)

The original Gradle loader used Properties.load(InputStream), which decodes
ISO-8859-1. The private file is valid UTF-8, and this decoding difference changed
the store-password value. The loader now explicitly decodes strict UTF-8,
rejects malformed input, removes only an optional leading file BOM and calls
Properties.load(Reader). It preserves password whitespace and standard property
escapes; it does not trim, normalize or guess passwords. Save the file as UTF-8.

Structural inspection found one occurrence of each required key, no BOM, no
surrounding whitespace, quote delimiters or backslash escapes. The storeFile
resolves to the intended android/keystore/allflag-upload-key.jks. Alias and
key-password parsing are unchanged between the old and new loaders.

The corrected Gradle script compiles, but flutter build appbundle --release
still fails at signReleaseBundle with the store password/integrity error.
An independent JDK check using the same UTF-8 Properties semantics also fails
store authentication, so the remaining failure is not specific to Gradle.

A separate read-only JKS diagnostic loaded the certificate and encrypted key
entry without performing the store-integrity check, then successfully unlocked
the private-key entry with the configured keyPassword. The public certificate
matches the expected SHA-256 above. This isolates the remaining mismatch to the
configured storePassword. It does not establish successful store integrity or
an artifact signature, and integrity validation was NOT bypassed in Gradle.

The human-verified interactive store password must be reconciled locally with
the UTF-8 storePassword value saved in key.properties. No private values were
printed, no credentials or JKS were modified, and no upload occurred. APK/AAB
signature verification remains blocked. The APK build is not repeated after
this AAB failure because the requested success prerequisite was not met.

After the loader fix, flutter analyze reports no issues and flutter test passes
all 7 tests. Git exclusions remain effective and neither private file is tracked.
Neither final APK nor AAB exists at its expected output path.

### Latest retry after manual storePassword re-entry

The owner reported re-entering storePassword and authorized an AAB-first retry.
flutter build appbundle --release still failed at signReleaseBundle with the
same keystore password/integrity error. Credentials and keystore contents were
not read or modified during this retry. Both private files remain ignored and
untracked. Because AAB success was the prerequisite, the APK build, artifact
signature checks, analysis and tests were not repeated in this retry. The latest
completed analysis and 7-test run above remain passing; signing is still blocked.
