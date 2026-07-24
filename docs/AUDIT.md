# Shadow (شادو) — Code Audit

**Date:** 2026-07-24
**Auditor:** read-only session (no files modified except this report)
**Scope audited:** `d:\Shadow\app` (the live project). A second copy exists at `d:\Shadow\_backup_old\UniAccess` — not audited in depth; see risks.

---

## 1. Summary — what this project actually is today

This is a **FlutterFlow-exported project**, not the greenfield, hand-written app described in `AGENTS.md`. The build tooling, folder layout (`lib/flutter_flow/`, `lib/pages/`, `lib/components/`, FFAppState), and default README ("UniAccess… FlutterFlow projects…") all confirm it. **It contradicts the brief on several decided points** and should be understood on its own terms, not the brief's.

The good news: the four modes are **not empty shells**. A prior developer hand-wrote real integration code in `lib/custom_code/actions/` — a working Deepgram WebSocket streaming transcriber, and real HTTP calls to an AI vision/text model. The UI buttons are genuinely wired to these calls. This is further along than "scaffolding."

The bad news, and it is significant:
- **The AI provider is OpenAI GPT-4o, not Google Gemini** as the brief specifies.
- **State management is `provider` / FlutterFlow's `FFAppState`, not Riverpod.**
- **There is no localization system.** Every Arabic string is hardcoded in widgets. The app declares only the English locale.
- **RTL is not configured** at the app level.
- **Zero accessibility semantics** exist in an app whose entire purpose is accessibility.
- **There is no git repository at all.**
- **Firestore security rules are wide open** (`allow read, write: if true`) on data the brief itself flags as PDPL-sensitive.
- **Nothing persists.** No transcript saving, no retention, no consent screen — none of the M1 data requirements exist.
- The "emergency" button is a **non-functional mockup** and is labelled exactly the way the owner said never to ship.

Net: a promising, partially-wired FlutterFlow prototype whose live-caption and AI paths look real in code, sitting on top of serious security, privacy, architecture, and accessibility gaps. Treat it as a demo, not a foundation — several core decisions must be reconciled with the brief before more is built.

---

## 2. Mode status table

I could not execute the app (no runtime keys, no device this session), so "APPEARS FUNCTIONAL" here means **I traced the full code path from user action → real service call → displayed result**, and it is complete and plausible — not that I saw it run. Every mode depends on a real API key supplied at build time via `--dart-define`; with no key, each returns an Arabic error string.

| Mode | Classification | Evidence |
|---|---|---|
| **1. Deaf — live captions** | **APPEARS FUNCTIONAL** (code path complete; unverified at runtime) | Button at `deaf_mode_transcription_widget.dart:404` → `startRealtimeTranscription()` → `transcription_mobile.dart` opens a real Deepgram WS (`wss://api.deepgram.com/v1/listen`, `language=ar&model=nova-2`, interim results), streams PCM16 mic audio via `record`, buffers finals, pushes to `FFAppState().liveText`, which the UI renders live (`:308`). Start/stop, clear (`:497`), and a font-size slider work. **Caveat:** the "save" part of "copy/save/clear" does **not** exist — no persistence. |
| **2. Visual — AI vision** | **APPEARS FUNCTIONAL** (code path complete; unverified) | `visual_assistance_mode_widget.dart:62` → `analyzeImageWithGpt4o()` posts a base64 image to OpenAI `gpt-4o` with an Arabic describe/read-text prompt, then `:76` speaks the result via `speakArabicText()` (`flutter_tts`, `ar-SA`). Full path present. |
| **3. Learning — simplify PDF** | **APPEARS FUNCTIONAL** (code path complete; unverified) | `learning_support_mode_widget.dart:81` → `processDocumentWithGpt4o()` extracts PDF text with `syncfusion_flutter_pdf`, sends summarize/simplify/quiz prompt to `gpt-4o`, displays result. Truncates at 8000 chars. |
| **4. Motor — voice control + quick-contact** | **PARTIALLY WIRED** | Voice control is real: `physical_assistance_mode_widget.dart:40` → `listenForVoiceCommand()` (Deepgram, 10s window) → Arabic-keyword navigation between modes (`:47–59`). **But** the flagship "quick-contact / emergency" button is a **fake**: `_showEmergencyDialog` (`:62`) shows a dialog whose "اتصال" (call) button just runs `Navigator.pop` (`:91`) — it dials no one. No `url_launcher`, no `tel:` anywhere. |

---

## 3. What genuinely works (in code)

- **Real Deepgram streaming transcription** — the standout. Proper PCM16 streaming, interim + final handling, session restart on socket drop, AAC fallback encoder, mic-permission check, buffered accumulation. This is real engineering, not a stub.
- **Real GPT-4o integration** for vision (describe / read-text) and document processing (summarize / simplify / quiz), with Arabic system prompts and UTF-8-safe decoding.
- **Arabic TTS** via `flutter_tts` (`ar-SA`), with stop-before-speak.
- **Voice-command navigation** mapping Arabic keywords to routes.
- **Route-assistant** (`ask_route_assistant.dart`) with a hardcoded King Saud University accessibility knowledge base — though I found no page actually calling it (see §4).
- **Four-card home screen** (`welcome_selection`) with correct Arabic labels navigating to all four modes.
- **`flutter analyze` is clean of errors:** 483 issues, **all `info`-level** (0 errors, 0 warnings) — mostly `prefer_const_constructors` and deprecated `withOpacity`.
- **API keys for Deepgram/OpenAI are NOT in source** — passed at build time via `--dart-define`. Correct approach.

---

## 4. What looks finished but isn't (read this section closely)

1. **The "emergency" button contacts nobody.** It looks like the brief's quick-contact feature but is a dead mockup (`Navigator.pop` only). Worse, it is labelled **"🆘 مساعدة طارئة"** / **"الاتصال بالأمن الجامعي"** (emergency / call university security) — the owner's answer #7 explicitly said do **not** ship anything labelled "emergency," and to make it a user-configured `tel:` quick-contact labelled "اتصال سريع." Current state is both non-functional *and* the disallowed framing.

2. **"Live captions" has no save/persistence.** The UI implies copy/save/clear, but `liveText` lives only in memory in `FFAppState`. Close the screen and it's gone. **None** of answer #6's M1 data requirements exist: no local persistence, no visible delete-all, no 30-day auto-expiry, no first-run consent screen. `initializePersistedState()` (`app_state.dart:19`) is an empty stub.

3. **Firebase looks integrated but stores nothing.** `initFirebase()` runs at startup and Firestore schema classes exist (`transcriptions_record.dart`, `documents_record.dart`, `user_profile_record.dart`), but **no app code ever reads or writes Firestore.** It's wired to the engine but the engine drives no wheels — dead weight that still ships live credentials and open rules.

4. **"Arabic-first" is cosmetic, not systemic.** Arabic text is correct but **hardcoded in every widget**. There is no localization file, no `ar` locale — `main.dart:81` declares `supportedLocales: [Locale('en', '')]` only. The brief's hard rule ("no hardcoded strings anywhere, all text through localization, `ar` default") is not met. English is not "secondary and optional" — it is the only declared locale.

5. **RTL is not actually configured.** No `Directionality`, no app-level `TextDirection.rtl`. Layout relies on per-widget manual alignment (`TextAlign.end`, etc.). The one explicit direction in the codebase is `TextDirection.ltr` (`flutter_flow_widgets.dart:310`). It may *look* right-to-left in places by hand, but it is not systematically RTL.

6. **No accessibility semantics whatsoever.** Zero `Semantics` / `semanticLabel` / `semanticsLabel` across `pages/` and `components/`. For an app built for screen-reader, switch, and low-vision users, "accessibility is the product" is currently unmet — it is a normal app with Arabic text on it.

7. **The test suite tests nothing and fails.** `test/widget_test.dart` is the default "Counter increments smoke test," which doesn't match this app; it **fails** (pending-timer assertion) — 0 passed / 1 failed. There is no coverage of the service paths or the academic-integrity guardrail.

8. **Strict analysis is not enabled.** `analysis_options.yaml` uses default `flutter_lints` only — no `strict-casts` / `strict-raw-types` as the brief requires.

9. **The academic-integrity guardrail is weak.** The "never do the student's homework" boundary is partially present (the learning-mode "quiz" prompt asks for review questions), but nothing prevents the vision or route assistants from answering exam content, and there's no UI statement of the boundary. Not enforced as the brief demands.

10. **`ask_route_assistant.dart` appears orphaned** — a complete GPT-4o feature with a KSU knowledge base, but no page calls it. Dead code, or an unfinished wire-up. (Uncertain which.)

---

## 5. Security and privacy findings

**Report gives file:line only; secret values are not reproduced here.**

- **CRITICAL — Firestore rules fully open.** `firebase/firestore.rules:5-23`: `allow create/read/write/delete: if true` on `transcriptions`, `documents`, and `user_profile`. Anyone with the project ID can read/write/delete all data. For PDPL-sensitive disability data this is a serious exposure. (Currently no app data flows here — but the door is open the moment it does.)
- **HIGH — Firebase config committed in source.** Web API key + project identifiers hardcoded at `lib/backend/firebase/firebase_config.dart:10`. Android config key at `android/app/google-services.json:18`. `google-services.json` and `ios/Runner/GoogleService-Info.plist` are both present in the tree. (Firebase client keys are not secrets by themselves, but combined with the open rules above they enable direct DB access.)
- **MEDIUM — Deepgram token passed as a URL query parameter** (`&token=$_apiKey` in `transcription_mobile.dart`, `listen_for_voice_command.dart`, `start_realtime_transcription.dart`). Tokens in URLs are more prone to logging/caching leakage than an `Authorization` header.
- **MEDIUM — verbose debug logging of audio/transcript flow.** `transcription_mobile.dart` `debugPrint`s transcript text and a key suffix. The brief says nothing sensitive in logs; transcript content is sensitive. (Debug-only, but present.)
- **LOW/GOOD — no LLM/ASR keys in source.** OpenAI and Deepgram keys come from `--dart-define` at build time. Correct.
- **PRIVACY GAP — no consent, no retention, no delete-all** (see §4.2). Audio is streamed to a third party (Deepgram) and images/PDF text to OpenAI with no user-facing disclosure. The lecturer-as-data-subject consent the owner asked for does not exist.
- **PROVIDER MISMATCH with privacy implications.** The brief's whole free-tier/PDPL discussion is about Gemini/Vertex. This app uses **OpenAI**, whose data-handling terms are different and were never assessed in the brief. Needs a deliberate decision, not an accidental one.

---

## 6. Technical debt and risks

- **No version control.** `git status` in both `d:\Shadow` and `d:\Shadow\app`: *"not a git repository."* No history, no `.gitignore`, no way to see what changed or recover from a bad edit. On a project with committed API config, this is itself a risk. **This alone would be a significant finding.**
- **Provider divergence from the brief** (OpenAI vs Gemini, provider vs Riverpod). No `TranscriptionService` / `VisionService` / etc. abstract interfaces exist — AI SDKs are called directly from feature code, the opposite of the brief's "providers behind interfaces." Swapping OpenAI→Gemini today means editing feature code.
- **Duplicate project copy** at `d:\Shadow\_backup_old\UniAccess` — risk of edits landing in the wrong tree; the old package id `com.mycompany.uniaccess` appears in the `.claude` settings.
- **Identity confusion:** package/Firebase project is `uni-access-4h4y54` / old bundle `com.mycompany.uniaccess`; pubspec name is `shadow`; README says "UniAccess." Three names for one app.
- **Failing, meaningless test** blocks any "CI on green" claim. No CI config found (no `.github/workflows`).
- **483 analyzer infos** — cosmetic but noisy; will bury real warnings later.
- **iOS untested** (expected per owner answer #9) but Firebase `GoogleService-Info.plist` is present, implying some iOS wiring exists.
- **`transcription_web.dart` is excluded from analysis** (`analysis_options.yaml`) — unanalyzed code path.

---

## 7. Open questions I cannot answer from the code alone

1. **Is the OpenAI/GPT-4o choice intentional, or drift?** The brief mandates Gemini. This is a strategic decision (cost, PDPL, Vertex residency) that changes §5 materially.
2. **Do the AI paths actually return good results at runtime?** I traced code, not behavior. Deepgram Arabic WER on real code-switched lecture audio — the owner's own M1 spike — is unmeasured.
3. **Is this FlutterFlow project meant to continue in FlutterFlow, or be migrated to the hand-coded architecture in the brief?** That decision governs almost everything else (Riverpod, interfaces, localization).
4. **Which is the source of truth — `app/` or `_backup_old/UniAccess`?** And is anything in the backup newer?
5. **Was Firestore ever intended to store transcripts,** or is the schema leftover FlutterFlow scaffolding?
6. **Is the Firebase project `uni-access-4h4y54` a throwaway or the real one?** Determines urgency of the open-rules fix.
7. **Was there ever a prior `.claude/CLAUDE.md`?** Only `settings.local.json` exists now; no prior-session notes survive to tell me what was believed done.

---

## 8. Recommended next three actions (priority order)

1. **Initialize git and lock down Firebase — today, before any feature work.**
   *Why:* You cannot safely change a codebase you can't diff or revert, and right now anyone can read/delete disability data via the open Firestore rules. Create a repo, add a `.gitignore` that excludes `google-services.json`, `GoogleService-Info.plist`, and build artifacts, make an initial commit, then rotate the Firebase keys and replace the `if true` rules with authenticated, per-user rules. Low effort, removes the two highest risks.

2. **Make one explicit decision: OpenAI-as-is vs migrate-to-brief — and record it.**
   *Why:* Everything downstream (Gemini vs GPT-4o, Riverpod vs provider, localization, service interfaces, PDPL story) forks on this. The app works today on OpenAI; the brief says Gemini behind interfaces. Don't let it stay accidental. If keeping OpenAI, do a PDPL/data-processing review of OpenAI's terms. If migrating, introduce the `TranscriptionService`/`VisionService` interfaces first so the swap is one file, exactly as the brief intended.

3. **Close the three honesty gaps in the modes: the fake emergency button, the missing persistence/consent, and accessibility semantics.**
   *Why:* These are the items most likely to be mistaken for "done." Relabel and actually wire the quick-contact to a user-set `tel:` (per owner answer #7); implement local transcript persistence with delete-all + 30-day expiry + a first-run consent screen (answer #6); and add `Semantics` labels to every control — for an accessibility app this is the product, not polish. Replace the failing default test with real tests on the service paths and the integrity guardrail as you go.

---

*End of audit. No implementation performed; no files modified except this report.*
