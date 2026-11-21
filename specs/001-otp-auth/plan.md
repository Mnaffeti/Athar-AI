# Implementation Plan: OTP Authentication (Telegram & Email)

**Branch**: `001-otp-auth` | **Date**: 2026-11-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-otp-auth/spec.md`

## Summary

Replace the mocked sign-in with real one-time-code sign-in by email or Telegram, for an academic demo on free tiers.
- Supabase Auth generates, expires and verifies the codes and keeps sessions.
- Brevo delivers the emails as Supabase's custom SMTP server.
- Telegram codes go out through Supabase's Send SMS hook to a small Edge Function that forwards them to Athar's Telegram bot.
- A second Edge Function receives bot messages and links each user's shared phone number to their chat.
- The Flutter app gets one `AuthService`, a code-entry screen, and small changes to the sign-in, splash, plan and profile screens.

## Technical Context

**Language/Version**: Dart ^3.9.2 / Flutter (app); TypeScript on Deno (Supabase Edge Functions)

**Primary Dependencies**: `supabase_flutter`, `url_launcher` (new); Supabase Auth, Postgres and Edge Functions; Telegram Bot API; Brevo SMTP relay; `standardwebhooks` (hook signature check)

**Storage**: Supabase Postgres: `profiles`, `telegram_links` ([data-model.md](data-model.md)); session persisted on device by `supabase_flutter`

**Testing**: `flutter test` (unit), `deno test` (function helpers), manual end-to-end per [quickstart.md](quickstart.md)

**Target Platform**: Android and iOS (existing Flutter targets); the web platform also builds

**Project Type**: mobile app + serverless backend

**Performance Goals**: code arrives within 30 s; sign-in in under 60 s (spec SC-001, SC-002)

**Constraints**: $0/month; Supabase free plan (project pauses after 7 days idle); Brevo free daily cap; no secrets in the repo

**Scale/Scope**: academic demo, a handful of users; 2 Edge Functions, 1 migration, 1 new screen, 4 changed screens

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template, so there are no ratified principles to gate on. **Result: pass (no gates).** Run `/speckit-constitution` if you want principles enforced on later plans.

Post-design re-check: still no gates. Design follows the existing codebase conventions (`setState` screens, static services in `lib/services/`).

## Project Structure

### Documentation (this feature)

```text
specs/001-otp-auth/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── app-auth-ui.md
│   ├── send-sms-telegram.md
│   └── telegram-webhook.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── main.dart                         # + Supabase.initialize from --dart-define
├── models/onboarding_answers.dart    # + toJson / fromJson
├── services/auth_service.dart        # NEW: wraps Supabase auth + profiles
├── utils/phone.dart                  # NEW: normalizeE164()
└── screens/
    ├── splash_screen.dart            # route by session
    ├── auth/sign_in_screen.dart      # email + Telegram, no Apple/Google
    ├── auth/verify_code_screen.dart  # NEW: code entry, resend, bot link step
    ├── onboarding/plan_screen.dart   # save profile if already signed in
    └── profile/profile_screen.dart   # + Sign out

supabase/
├── config.toml
├── migrations/<timestamp>_auth_profiles.sql
└── functions/
    ├── _shared/phone.ts              # normalize + own-contact check (+ phone_test.ts)
    ├── send-sms-telegram/index.ts
    └── telegram-webhook/index.ts

test/
├── phone_test.dart
└── onboarding_answers_test.dart
```

**Structure Decision**: Keep the Flutter app where it is, and add a top-level `supabase/` folder, which is the layout the Supabase CLI expects. No separate backend service.

## Complexity Tracking

No constitution violations. Spec deviations accepted for the demo (recorded in spec Clarifications and in [research.md](research.md) R6 and R7):

| Spec rule changed | Why | Replaced by |
|---|---|---|
| 5 wrong attempts per code | Supabase has no per-code counter | 30 verifies per 5 min per IP (built-in) |
| 5 codes per destination per hour | Not built in; would need custom tables | 60 s cooldown + app-wide hourly cap |
| 30-day inactivity expiry | Pro plan only | Session lasts until sign-out |
| Bot compares the typed vs shared number | Would need pending state per chat | Link the shared number; the typed number fails until linked |
