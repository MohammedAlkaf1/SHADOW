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
