# Shadow — Backlog

Items deferred but not lost. Recorded 2026-07-24. See `docs/AUDIT.md` for full evidence.

## High priority (do immediately after the Deepgram ASR spike)

### 1. Accessibility semantic labels — ✅ RESOLVED (commit 5691e32, 2026-07-24)
There are currently **zero** `Semantics` / `semanticLabel` across `lib/pages/` and `lib/components/`. This is an accessibility app.
- **Impact:** blind users **cannot use mode 2 (visual assistance) via TalkBack** today — controls are unlabelled. The same gap affects every screen for screen-reader and switch users.
- **Action:** add semantic labels to every interactive control, screen by screen, starting with mode 2. Test with TalkBack on a real device.
- **Priority rationale:** highest-priority feature work after the ASR spike resolves — an accessibility app that its target users can't navigate has no floor.

### 2. Emergency button — fix behaviour and label — ✅ RESOLVED (commit 4c8b84c, 2026-07-24)
`lib/pages/physical_assistance_mode/physical_assistance_mode_widget.dart` (`_showEmergencyDialog`, ~L62; FAB ~L114).
- **Current state:** the "اتصال" (call) button only runs `Navigator.pop` — it dials nobody. Labelled "🆘 مساعدة طارئة" / "الاتصال بالأمن الجامعي".
- **Required:** a **user-configured quick-contact** that launches a `tel:` intent to a number the student sets in settings, labelled **"اتصال سريع"**.
- **Constraint (owner):** nothing may be labelled "طوارئ / emergency" until a university formally commits staff to answer it.

---

## Known bugs (record only — not yet fixed)

Observed 2026-07-25 during on-device testing. Recorded, deliberately **not** fixed yet.

### 3. RenderFlex overflow (18px) in feature_button_widget.dart
- **Where:** `lib/components/feature_button/feature_button_widget.dart` — used by the
  visual-assistance mode buttons ("صف المحيط" / "اقرأ النص").
- **Symptom:** a RenderFlex overflow of ~18px (the yellow/black overflow stripe) in
  the button's column layout on the test device (SM A536E, Android 15).
- **Likely area:** the fixed `height: 180.0` container + `EdgeInsets.all(40.0)`
  padding + 64px icon + text can exceed the available height at certain text
  scales/screen sizes. Needs a flexible/− height or reduced padding.
- **Not blocking:** visual only; buttons still function.

### 4. PDF file-picker crash (unknown_path) when picking from OneDrive
- **Where:** `lib/pages/learning_support_mode/learning_support_mode_widget.dart`
  (`_pickPdfFile`, uses `file_picker`).
- **Symptom:** picking a PDF that lives in OneDrive fails with an `unknown_path`
  error / crash (the file has no local path until hydrated by OneDrive).
- **Likely fix direction:** rely on `withData: true` bytes (already requested) and
  never assume a local path; handle the `unknown_path` PlatformException
  gracefully with an Arabic message; possibly copy to a temp file first.
- **Not blocking:** local (non-OneDrive) PDFs work.

---

## Deliberately skipped (not oversights)

### Orient / read-back step
On 2026-07-24 the owner **deliberately skipped** the "orient / read-back" step
(where the agent restates its understanding of the repo before acting), because
prior work in the session had already demonstrated that understanding. This was
a conscious decision, not an omission — recorded here so it is not later mistaken
for a missed step.

---

_Backlog only — do not action items here without them being scheduled into the working order in `AGENTS.md`._
