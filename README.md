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
     "OPENAI_API_KEY": "your_openai_key",
     "PLATFORM_BASE_URL": "http://localhost:3000/api"
   }
   ```
   `env.json` is git-ignored — it is never committed. `env.example.json` (empty
   placeholders) is the committed template. Deepgram powers live captions and voice
   control; OpenAI powers vision and document simplification (leave it "" if you
   don't have one yet — those two modes just show a "key missing" message).
   `PLATFORM_BASE_URL` points at the Shadow Platform backend (see
   `D:\Shadow\platform`, `docs/API.md` there) — defaults to
   `http://localhost:3000/api` for local dev if omitted.

## Platform integration (login, mode gating, adaptation)

This app is a client of the separate Shadow Platform backend
(`D:\Shadow\platform`). On first launch (or after logout) the app shows a
**login screen** (email + password against the platform's demo accounts,
e.g. `student@demo.shadow.sa` / `Password123!` — see the platform's own
README for the full demo credential list). After login:

- The mode-selection (home) screen only shows the 4 top-level mode cards
  (deaf/visual/learning/physical) that are enabled on the student's
  SupportPlan on the platform — a card is hidden entirely if its
  `DEAF_MODE`/`VISUAL_MODE`/`LEARNING_MODE`/`PHYSICAL_MODE` tool code isn't
  in the platform's `enabledTools` response. Before login, or if nothing has
  ever been fetched from the platform yet, every mode stays visible
  (fail-open, matching the app's original behavior).
- Font sizes, text styles, alert sensitivity, etc. inside each mode are
  driven by the platform's **adaptation directives**
  (`lib/services/adaptation_directives.dart`) instead of a locally-held
  category/support-level — this app is never told the student's actual
  classification, only these already-decided, opaque values. See
  `lib/student/student_profile.dart` and the platform's `docs/API.md`.
- Usage events (`mode_opened`, `tool_used`, `provider_error` — abstract
  metadata only, never audio/image/PDF content or transcripts) are buffered
  locally and sent to the platform in batches (`lib/services/platform_client.dart`),
  either every 60 seconds or when a mode screen closes, whichever is first.
- **Offline-first:** if the platform is unreachable, the app keeps working
  with the last successfully-fetched profile/directives (cached via
  `lib/services/app_prefs.dart`), and queues usage events locally until
  connectivity returns. A dead platform connection never blocks a mode from
  working.
- The debug-only Developer Tools screen (`lib/pages/dev_tools`) still lets a
  developer override category/support-level locally without a platform
  session — useful for testing adaptation behavior without a live backend.

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
