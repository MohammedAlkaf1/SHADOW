# AGENTS.md — Shadow (شادو)

**This file is the source of truth for how to work in this repo. If any other document, chat message, or prior brief contradicts it, this file wins. Read it fully before touching anything.**

Last rewritten: 2026-07-24, after a full code audit (see `docs/AUDIT.md` — read it before your first change).

**Product scope:** this repo is the **Flutter app only** — Phase 1 of a larger
product. The university platform (auth, intake, specialist review, support plans,
dashboards, multi-tenancy) is **Phase 2+ and lives in a SEPARATE repository** —
do not scaffold it here. Full plan, decisions, and the held Phase 2 kickoff prompt
are in `docs/ROADMAP.md`. Architectural boundary to honour now: the AI features
(Deepgram, Kimi) process only academic content the student chooses (lecture
audio, slides, PDFs) — **never** medical reports or disability records.

---

## WHAT THIS REPO ACTUALLY IS

Shadow is an Arabic-first accessibility app for Saudi university students with disabilities, with four modes: deaf/live-captions, visual assistance, learning support, and motor/voice control.

**This is a FlutterFlow-exported project.** It is not a hand-written greenfield app. That has consequences you must accept, not fight:

- State management is **`provider` + FlutterFlow's `FFAppState`** (`lib/app_state.dart`).
- Folder layout is FlutterFlow's: `lib/flutter_flow/`, `lib/pages/`, `lib/components/`, `lib/custom_code/actions/`, `lib/backend/`.
- The AI provider for vision and document processing is **Kimi (Moonshot)**, OpenAI-compatible, behind `lib/services/ai_client.dart` (the swap point). The action files are still named `*_gpt4o.dart` for their callers but no longer use OpenAI.
- Live captions use **Deepgram** streaming over WebSocket (`lib/custom_code/actions/transcription_mobile.dart`).
- API keys are supplied at build time via `--dart-define` (e.g. `--dart-define=DEEPGRAM_API_KEY=... --dart-define=OPENAI_API_KEY=...`). They are **not** in source. Keep it that way.

A large amount of this code genuinely works. Treat it as a working prototype to be corrected in place — not a draft to be reimagined.

---

## HARD PROHIBITIONS — DO NOT MIGRATE

An earlier brief described a different architecture (Riverpod, Gemini, feature-first folders, service interfaces, `.env`/`flutter_dotenv`). **That brief was wrong about this repo. Ignore it.** Do not "helpfully" bring the code in line with it. Specifically:

1. **Do NOT introduce Riverpod** or any new state-management library. Keep `provider` / `FFAppState`.
2. **Do NOT switch AI providers on your own.** The provider for vision/learning is **Kimi (Moonshot)** (owner's explicit decision, 2026-07-25) and Deepgram for speech; both OpenAI-compatible/swappable via their service files. Do not add Gemini, Vertex, OpenAI, etc. without the owner's explicit direction.
3. **Do NOT restructure folders.** Keep the FlutterFlow layout. Do not create a `features/` tree, do not add abstract `*Service` interfaces, do not move files to "clean up" the structure.
4. **Do NOT run `flutter pub upgrade`** or bump package versions. The dependency set is pinned and working. If you believe a package genuinely must change, stop and ask first, with the specific reason.
5. **Do NOT reformat, rename, or rewrite working files** to match a style or architecture you prefer. Change only what the task requires.
6. **Do NOT regenerate anything through FlutterFlow** or overwrite `lib/flutter_flow/**` by hand unless a task explicitly says so.

If you find yourself editing a file the current task didn't name, stop — you are probably migrating instead of fixing.

---

## WHAT ACTUALLY NEEDS DOING (priority order)

These come from the audit. Do them **in place**, within the stack above.

1. **Version control + secret hygiene.** There is no git repo. Initialize one, add a `.gitignore` that excludes `google-services.json`, `GoogleService-Info.plist`, and build artifacts, then commit. Firebase config is currently committed in source.
2. **Firestore security.** Rules are wide open (`allow read, write: if true`). They must be locked down — **but see the auth question below; do not blindly apply a fix that breaks a no-auth app.**
3. **The fake "emergency" button.** In `physical_assistance_mode_widget.dart` the button dials no one and is labelled "🆘 مساعدة طارئة / الأمن الجامعي". Per the owner: it must be a **user-configured quick-contact** that launches a `tel:` intent, labelled **"اتصال سريع"**, never "طوارئ/emergency". Nothing may be labelled "emergency" until a university formally commits staff to answer it.
4. **Data requirements for live captions.** No persistence, retention, delete-all, or consent exist. Add: local-only transcript persistence, a visible delete control + delete-all in settings, auto-expiry defaulting to 30 days, and a first-run consent screen stating that audio is sent to a third party (Deepgram) — the lecturer is a data subject too.
5. **Accessibility semantics.** There are currently zero. This is an accessibility app; add `Semantics`/labels to controls as you touch each screen.
6. **Tests.** The only test is the default counter smoke test and it fails. Replace with real tests on the service paths and the academic-integrity boundary.
7. **RTL / localization.** Arabic is hardcoded and only `Locale('en')` is declared. Improve pragmatically and in place — this is not a mandate to introduce a full localization framework overnight or to migrate every string at once.

**Do not treat this list as a batch to run unattended.** One concern at a time, each shown as a plan before code, each a separate commit.

---

## THE QUESTION THE PRODUCT RESTS ON

Everything above is repairable at any time. **Whether Deepgram can transcribe a real Saudi university lecture — Modern Standard Arabic, code-switched with Hijazi/Saudi dialect and English technical terms, in a real room with real noise — is the one thing that is not yet answered, and the entire product depends on it.**

Nobody has tested this on real audio. Clean studio speech proves nothing. Before more effort goes into the caption UI, a real recorded lecture must be run through the exact Deepgram config the app uses, and the word error rate reported. If it is poor, that is a **provider** question, not a code question — and swapping ASR is the one architectural change that is on the table. Do not assume Deepgram works.

---

## HOW TO WORK

1. **Plan first, code second.** For anything non-trivial, show the plan — files touched, approach, risks — and wait for approval.
2. **Ask, don't assume.** If a task affects data, privacy, security, or user safety and this file doesn't settle it, stop and ask.
3. **One concern per commit.** Conventional Commits (`feat:`, `fix:`, `chore:`). But do not commit until git is initialized and `.gitignore` exists (task 1).
4. **Never leave the app non-building.** If a change breaks the build, fix or revert before ending your turn.
5. **Keys stay out of source and out of logs.** Transcript text and disability data are sensitive under Saudi PDPL — nothing sensitive in logs, analytics, or anywhere off-device except the audio/image/text a given AI call requires.
6. **Academic integrity.** Shadow explains, simplifies, summarizes, reviews. It does not answer exam questions or write assignments. Enforce this in prompts and state it in the UI.
7. **Explain decisions in plain language.** Assume the owner reads your code but wants the reasoning without reverse-engineering it.
