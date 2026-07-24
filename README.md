# UniAccess

A new Flutter project.

## Getting Started

FlutterFlow projects are built to run on the Flutter _stable_ release.

## Required configuration files (NOT tracked in git)

Two Firebase config files are **required to build the app** but are deliberately
**not** committed to this repository (they are listed in `.gitignore`). A fresh
clone will **not** build until you add them:

| File | Needed for |
|---|---|
| `android/app/google-services.json` | Android build |
| `ios/Runner/GoogleService-Info.plist` | iOS build |

If the Android build fails right after cloning with a Google Services / Firebase
error, a missing `google-services.json` is the most likely cause.

**Where to get them:** Firebase console → your project → **Project settings**
(gear icon) → **Your apps** → select the Android app (download
`google-services.json`) and the iOS app (download `GoogleService-Info.plist`).

**Keep your own copies OUTSIDE the repository** (e.g. a private password manager
or a secure local folder) so you can restore them into a fresh clone. Do **not**
commit them, and do **not** move them out of `.gitignore`.

## Building and running on Android

API keys are passed at build time with `--dart-define` (never committed). Replace
`YOUR_DEEPGRAM_KEY` / `YOUR_OPENAI_KEY` with the real keys. Deepgram powers live
captions and voice control; OpenAI powers vision and document simplification.

Prerequisites: `flutter doctor` all green, the two config files above in place, and
a device connected (`flutter devices` to confirm) or an emulator running.

**1. Build and run on a connected physical Android device** (debug), from the
`app/` directory:

```powershell
flutter run --dart-define=DEEPGRAM_API_KEY=YOUR_DEEPGRAM_KEY --dart-define=OPENAI_API_KEY=YOUR_OPENAI_KEY
```

**2. Build a release APK you can share / sideload**, from the `app/` directory:

```powershell
flutter build apk --release --dart-define=DEEPGRAM_API_KEY=YOUR_DEEPGRAM_KEY --dart-define=OPENAI_API_KEY=YOUR_OPENAI_KEY
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`. It is
currently **signed with the debug key** (see the TODO in `android/app/build.gradle`),
which is fine for testing and sideloading but **not** for the Play Store — a real
release signing config is needed before store distribution.

(The commands are identical in bash; just the same single line.)

**Note on minSdk:** if a build fails on an older device because the audio/`record`
plugin needs a higher API level, set `minSdkVersion 23` in `android/app/build.gradle`
and rebuild.
