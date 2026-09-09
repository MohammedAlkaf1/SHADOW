# Deepgram / Gemini API key architecture — known limitation

## Current state

`DEEPGRAM_API_KEY` and `GEMINI_API_KEY` are read via `String.fromEnvironment`
(`lib/services/ai_client.dart`, `lib/custom_code/actions/*.dart`) from
`env.json`, injected at build time with
`--dart-define-from-file=env.json`. This means:

- The keys are **not committed to git** (`env.json` is git-ignored; only
  `env.example.json` with empty placeholders is tracked). Verified: `git log
  -S` on the actual key values across all of history returns no hits.
- The keys **are compiled into the release APK/AAB binary** as string
  constants. `String.fromEnvironment` values are baked in at compile time —
  they are extractable from a release build via static analysis /
  decompilation (`strings`, apktool, etc.), same as any embedded client-side
  secret, regardless of obfuscation.

This is the deeper issue task item 3 refers to: env-var injection avoids a
*git* leak, but does not avoid a *client-side secret* leak. Anyone who
downloads the APK can extract a permanent Deepgram/Gemini key.

## Why this wasn't silently "fixed" by adding a backend proxy

The companion backend (`D:\Shadow\platform`) has an explicit, documented
architecture rule in its `AGENTS.md` / `src/lib/ai.ts`:

> EXPLICIT, USER-CONFIRMED EXCEPTION to this project's "no AI/chatbot inside
> the platform" rule. Scoped to [[exam generation, TTS, keyterm extraction]]
> only... **This is NOT license to add AI calls anywhere else in the app.**

The Flutter app's live AI features that need Deepgram/Gemini
(deaf-mode real-time transcription, the learning-support vision/chat mode,
voice-exam answer capture) are **not** in that scoped exception. Building a
new authenticated proxy for them — especially Deepgram's real-time
WebSocket transcription, which isn't a simple request/response proxy — is a
real feature/architecture decision (new endpoints, auth, rate limiting,
who bears the provider cost per request) that belongs to the team that set
that policy, not something to add unilaterally as a "hardening pass."

## What was done instead (this pass)

- Confirmed no key value has ever been committed to git history.
- Confirmed the app already fails safely without a key: `aiChatCompletion`
  returns a user-facing Arabic error (never crashes, never sends a request)
  when `GEMINI_API_KEY` is empty; the Deepgram call sites log-and-abort the
  same way.
- Confirmed `env.json`/`env.example.json` and the `.gitignore` entries are
  correct and unchanged.

## EXTERNAL ACTION REQUIRED before this is genuinely production-safe

A real fix requires a product/architecture decision plus new backend work:

1. Decide whether Deepgram/Gemini access for these three student-facing
   features is added to the platform's sanctioned AI exception list.
2. If yes: add authenticated server-side proxy endpoints in
   `D:\Shadow\platform` (a WebSocket relay for Deepgram real-time, and a
   REST proxy for Gemini vision/chat), and point the Flutter client at
   those instead of the provider APIs directly.
3. Until that exists, treat the current keys in `env.json` as inherently
   extractable from any release build — rotate them periodically, and do
   not treat "not in git" as "not exposed."
