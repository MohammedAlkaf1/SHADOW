# Shadow (شادو)

A Flutter client app for students with disabilities/support needs
(deaf/hard-of-hearing, visual, learning-difficulty, and motor-impairment
modes), backed by the separate Shadow Platform API (`D:\Shadow\platform`).

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
     "GEMINI_API_KEY": "your_gemini_key",
     "PLATFORM_BASE_URL": "http://localhost:3000/api"
   }
   ```
   `env.json` is git-ignored — it is never committed. `env.example.json` (empty
   placeholders) is the committed template. Deepgram powers live captions and voice
   control; Gemini powers vision, document simplification, and summarization
   (leave it "" if you don't have one yet — those modes just show a "key missing"
   message). Both keys are compiled into the client binary via `--dart-define` —
   they are extractable from a built APK, so treat them as **not fully secret**;
   for a public production release, proxy these calls through your own backend
   instead of calling Deepgram/Gemini directly from the client.
   `PLATFORM_BASE_URL` points at the Shadow Platform backend (see
   `D:\Shadow\platform`, `docs/API.md` there) — defaults to
   `http://localhost:3000/api` for local dev if omitted.

## Platform integration (login, mode gating, adaptation)

This app is a client of the separate Shadow Platform backend
(`D:\Shadow\platform`). On first launch (or after logout) the app shows a
**login screen** (email + password against the platform's accounts — see
the platform's own README/seed data for its demo-account list). After login:

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

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`. Release
builds require a real signing config — `android/app/build.gradle` fails the
build with an explicit error (rather than silently signing with the debug
key) if `android/key.properties` doesn't exist. See
`docs/RELEASE_SIGNING.md` to set it up. Also note: since
`assertProductionEndpointInRelease()` (`lib/main.dart`) refuses to run a
release build against a non-HTTPS/localhost/ngrok `PLATFORM_BASE_URL`, a
release APK built with the dev-default `env.json` will build successfully
but crash immediately on launch — set a real production URL first.

(The commands are identical in bash; just the same single line.)

**Note on minSdk:** if a build fails on an older device because the audio/`record`
plugin needs a higher API level, set `minSdkVersion 23` in `android/app/build.gradle`
and rebuild.

## Before a real (Play Store / production) release

This checklist is **not yet complete** — do these before shipping to real users:

- [x] **Release signing.** `android/app/build.gradle`'s `release` build type now
      requires `android/key.properties` and fails loudly if it's missing —
      it no longer falls back to the debug key. **EXTERNAL ACTION REQUIRED:**
      a real production keystore still needs to be generated by the team; see
      `docs/RELEASE_SIGNING.md`.
- [ ] **`PLATFORM_BASE_URL` must point at the real deployed backend**, not a
      local server or a temporary tunnel (e.g. ngrok). `assertProductionEndpointInRelease()`
      now makes a release build refuse to run against one — but a real
      production URL still needs to exist and be set in `env.json`.
      **EXTERNAL ACTION REQUIRED:** no production deployment of
      `D:\Shadow\platform` exists yet (it currently only runs against
      localhost Postgres/S3 — see that repo's `.env.local`).
- [x] **Privacy policy in-app.** Added (`lib/pages/settings/privacy_policy_screen.dart`,
      Settings → Legal → Privacy Policy, EN/AR). **EXTERNAL ACTION REQUIRED:**
      Google Play also requires a *hosted* privacy policy URL for the Play
      Console listing — publish this content (or equivalent) at a public URL.
- [ ] **API keys.** `DEEPGRAM_API_KEY`/`GEMINI_API_KEY` are compiled into the
      client via `--dart-define` and are extractable from the built APK —
      not committed to git, but not a real secret either. See
      `docs/API_KEY_ARCHITECTURE.md` for why proxying these through the
      backend is a product decision this pass didn't make unilaterally.
- [x] **Demo/seed accounts.** Confirmed the platform backend has no production
      deployment — `student@demo.shadow.sa` etc. are local Postgres seed data
      (`platform/prisma/seed.ts`), not a live account. Scrubbed the credential
      from this app's docs regardless. Revisit if/when the backend is deployed
      publicly.
