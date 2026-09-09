# Android release signing

Release builds (`flutter build apk --release` / `--release` App Bundle) are
signed with `android/key.properties`, which is git-ignored. This file does
**not** exist in the repository and must be created locally (or injected by
CI as a secure file) before a release build will succeed. The Gradle build
deliberately fails with an explicit error if it's missing — it does **not**
fall back to the Android debug key, so a release artifact signed with the
debug key can never be produced or distributed by accident.

## One-time setup (production keystore)

This has not been generated for this project — it requires a decision the
team must make (who holds the keystore, backup/escrow policy), so it is
**not invented here**. To create it:

```
keytool -genkey -v -keystore shadow-release.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias shadow
```

Store the resulting `.jks` file and its passwords in a password manager /
secrets vault, not in the repo. **If this keystore is ever lost, you cannot
publish updates to an existing Play Store listing under the same app** — so
back it up somewhere durable before the first Play Store upload.

## Local build

1. `cp android/key.properties.example android/key.properties`
2. Fill in `storeFile` (path to the `.jks`), `storePassword`, `keyPassword`,
   `keyAlias`.
3. `flutter build apk --release`

## CI

Do not commit the keystore or `key.properties`. Inject them as CI secrets
(e.g. GitHub Actions `secrets.*`, base64-decoded into a temp file) only in
workflows that actually build a release artifact for distribution — the
default CI workflow in this repo does not build a signed release, so it
requires no signing secrets.

## Status

**EXTERNAL ACTION REQUIRED before a real Play Store release:** a production
keystore must be generated and its custody decided by the team. Until then,
release builds can still be produced locally for testing using a
locally-generated, non-committed keystore (same `keytool` command above) —
that is a throwaway signing identity, not the one to publish to Play Store.
