# Shadow — Backlog

Items deferred but not lost. Recorded 2026-07-24. See `docs/AUDIT.md` for full evidence.

## High priority (do immediately after the Deepgram ASR spike)

### 1. Accessibility semantic labels
There are currently **zero** `Semantics` / `semanticLabel` across `lib/pages/` and `lib/components/`. This is an accessibility app.
- **Impact:** blind users **cannot use mode 2 (visual assistance) via TalkBack** today — controls are unlabelled. The same gap affects every screen for screen-reader and switch users.
- **Action:** add semantic labels to every interactive control, screen by screen, starting with mode 2. Test with TalkBack on a real device.
- **Priority rationale:** highest-priority feature work after the ASR spike resolves — an accessibility app that its target users can't navigate has no floor.

### 2. Emergency button — fix behaviour and label
`lib/pages/physical_assistance_mode/physical_assistance_mode_widget.dart` (`_showEmergencyDialog`, ~L62; FAB ~L114).
- **Current state:** the "اتصال" (call) button only runs `Navigator.pop` — it dials nobody. Labelled "🆘 مساعدة طارئة" / "الاتصال بالأمن الجامعي".
- **Required:** a **user-configured quick-contact** that launches a `tel:` intent to a number the student sets in settings, labelled **"اتصال سريع"**.
- **Constraint (owner):** nothing may be labelled "طوارئ / emergency" until a university formally commits staff to answer it.

---

_Backlog only — do not action items here without them being scheduled into the working order in `AGENTS.md`._
