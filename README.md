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

## API keys — set once in env.json (never in the command)

Keys are read at build time via `String.fromEnvironment`, populated from a local
JSON file with `--dart-define-from-file`. Enter your keys **once** and they stay
out of the command line and logs.

1. Copy the template to the real (git-ignored) file — once:
   ```powershell
   Copy-Item env.example.json env.json
   ```
2. Open **`env.json`** and paste your keys between the quotes:
   ```json
   {
     "DEEPGRAM_API_KEY": "your_deepgram_key",
     "OPENAI_API_KEY": "your_openai_key"
   }
   ```
   `env.json` is git-ignored — it is never committed. `env.example.json` (empty
   placeholders) is the committed template. Deepgram powers live captions and voice
   control; OpenAI powers vision and document simplification (leave it "" if you
   don't have one yet — those two modes just show a "key missing" message).

## Building and running on Android

Prerequisites: `flutter doctor` all green, `google-services.json` in place (see
above), `env.json` filled in, and a device connected (`flutter devices`).

**1. Build and run on a connected physical Android device** (debug), from the
`app/` directory:

```powershell
flutter run --dart-define-from-file=env.json
```

**2. Build a release APK you can share / sideload**, from the `app/` directory:

```powershell
flutter build apk --release --dart-define-from-file=env.json
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`. It is
currently **signed with the debug key** (see the TODO in `android/app/build.gradle`),
which is fine for testing and sideloading but **not** for the Play Store — a real
release signing config is needed before store distribution.

(The commands are identical in bash; just the same single line.)

**Note on minSdk:** if a build fails on an older device because the audio/`record`
plugin needs a higher API level, set `minSdkVersion 23` in `android/app/build.gradle`
and rebuild.
