# Shadow — Full Product Roadmap

Recorded 2026-07-24. This is the product plan beyond the Flutter app: the app
**and** the university platform (intake, specialist review, needs assessment,
support plans, dashboards, multi-tenancy).

**This repo (`app/`) is Phase 1 — the Flutter app.** The platform (Phase 2+) is a
**separate repository**, not a change to this one. Do not scaffold the platform
here. The Phase 2 kickoff prompt is held at the bottom of this file until Phase 1
is done.

---

## Scope — what "full" contains

The current app is ~20% of the product.

**Exists, needs finishing:** the four accessibility modes (real Deepgram + GPT-4o).
Missing: accessibility semantics, transcript persistence, consent, quick-contact
button.

**Does not exist at all:** authentication (4 roles), student intake, encrypted
medical-report storage, specialist review queue + classification, needs
assessment → support level, support-plan engine + revisions, app↔platform link,
continuous evaluation, dashboards, reporting, multi-tenancy, audit log, admin
tooling.

## Honest timeline (1–2 devs + AI, steady)

| Phase | Scope | Duration |
|---|---|---|
| 1 | Finish the app to pilot quality | 3–4 weeks |
| 2 | Platform core: auth, intake, review, assessment, plans | 8–10 weeks |
| 3 | App ↔ platform integration | 3–4 weeks |
| 4 | Dashboards, reporting, multi-tenancy | 5–6 weeks |
| 5 | Security hardening, compliance, pilot prep | 4 weeks |

**~5–6 months to a real university pilot.** Deck framing "في طور الاختبار والتحسين"
is accurate — keep it.

## Legal — the platform changes everything (PDPL)

Today the app holds **no** central personal data — the strongest privacy position
possible. The platform ends that: it stores **medical reports and disability
records for identifiable students**, making the operator a **controller of
sensitive personal data** under Saudi PDPL. Obligations: lawful basis + explicit
consent for health data; data residency in the Kingdom (or documented transfer
basis); DPAs with each university; retention/deletion policy; breach
notification; data-subject rights (access/correction/deletion); likely a DPIA
before launch. **Needs a PDPL lawyer, budgeted now.**

Sending student data to OpenAI/Deepgram needs a documented basis and appropriate
terms — assessment never done (flagged in AUDIT.md). Do it in **Phase 2, not
Phase 5**.

> **Architectural boundary that limits exposure (agreed):** the AI features
> (Deepgram, GPT-4o) only ever process **academic content the student chooses** —
> lecture audio, slides, PDFs. They must **never** touch the medical report or
> disability record. Keeping sensitive records off all third-party AI shrinks the
> PDPL surface materially. Build Phase 2 with this boundary explicit.

## Decisions made now (expensive to reverse)

- **4.1 Stack — Laravel** (if the team already builds in Laravel; **to be
  confirmed by the owner**). Backend Laravel + Sanctum; frontend Blade+Livewire
  or Inertia+React; **PostgreSQL**; S3-compatible object storage in a KSA region,
  encrypted. The app talks to Laravel's API, not a DB directly.
- **4.2 Hosting/residency** — health data inside the Kingdom. Verify current
  AWS/Azure KSA-region availability live; local Saudi providers viable. Decide
  before Phase 2 — migrating a live DB across jurisdictions is painful.
- **4.3 Firebase** — currently initialized-but-unused, rules closed. Once Laravel
  exists, Firebase has no role. Remove in Phase 2 (small refactor: it's woven
  through `backend.dart`, `firebase_config.dart`, `main.dart`).
- **4.4 Auth** — one identity system owned by the platform; the app authenticates
  against Laravel and receives a token. No separate auth in the app. **Open
  question for the university: SSO/SAML vs platform-issued accounts** (universities
  usually prefer SSO). Ask early — reshapes Phase 2.
- **4.5 Tenancy** — shared multi-tenant, strict row-level isolation, one
  deployment for all universities.

## Build order (each phase ends usable)

- **Phase 1 — finish the app (3–4 wk):** semantics, quick-contact button,
  persistence, consent screen, device testing, ASR spike result. Unchanged by the
  "full" decision; also the demo while the platform is built.
- **Phase 2 — platform core (8–10 wk):** Laravel scaffold, Postgres schema, RBAC
  (4 roles), audit log from day one, registration/profile, encrypted medical-report
  upload, specialist review queue + classification (taxonomy from the owner's Word
  doc), needs assessment → support level, support-plan generation + revisions.
  *Ends: a specialist reviews a real case and produces a support plan.*
- **Phase 3 — integration (3–4 wk):** app authenticates against the platform;
  identity flows through; the support plan controls which modes/tools are enabled;
  usage events flow back. *Ends: the app reflects the specialist-approved plan.*
- **Phase 4 — visibility (5–6 wk):** per-role dashboards, university reporting,
  multi-tenancy with verified isolation, admin tooling.
- **Phase 5 — hardening (4 wk):** pen test, PDPL compliance review, DPAs,
  retention automation, incident procedures, load testing, docs/training.

## This week (do NOT start Phase 2 yet)

1. **Run the ASR spike** with a real recorded lecture (harness ready at
   `tool/asr_spike/`). If Deepgram can't handle real Saudi lectures, the flagship
   feature — and the platform built around it — rests on a broken core.
2. **Confirm the stack** (Laravel or not).
3. **Talk to the target university:** SSO vs issued accounts, and what their
   infosec review will require. Both reshape Phase 2; both are free to ask now.

Meanwhile, run the Phase 1 work (valid regardless of everything above).

---

## HELD — Phase 2 kickoff prompt (do not use until Phase 1 is done)

```
New workstream: the Shadow university platform. This is separate from
the Flutter app — a new repository, not a change to the existing one.

Before writing any code, produce a technical plan for review.

Context:
- Laravel + PostgreSQL, hosted in Saudi Arabia
- Four roles: student, faculty, specialist, admin
- Multi-tenant: one deployment, many universities, isolated data
- Handles medical reports and disability records — sensitive personal
  data under Saudi PDPL
- An existing Flutter app will authenticate against this platform's API

Deliver, in order, stopping after each:

1. Read AGENTS.md and docs/AUDIT.md from the app repo for product
   context. Restate the platform's purpose and list every ambiguity.

2. Database schema covering: tenants, users, roles and permissions,
   student profiles, disability categories (seeded), support levels
   (seeded), documents, assessments, support plans, plan revisions,
   usage events, and an audit log. Show it as an ERD plus migrations.
   The disability categories and support levels come from the
   classification document — ask me for it.

3. The permission model in detail. Specifically: how a faculty member
   is prevented from ever reading a medical report, enforced at the
   database level and not only in application code.

4. Document handling design: upload, encryption at rest, access
   control, audit trail, retention and deletion.

5. API design for the Flutter app: authentication, what the app can
   read and write, and how support plans control which features are
   enabled on the device.

Do not scaffold anything until I approve the schema and permission
model. Those two are the expensive things to get wrong.
```
