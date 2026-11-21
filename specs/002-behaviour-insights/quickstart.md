# Quickstart: validate behaviour insights

## Prerequisites

- Feature 001 deployed: Supabase project, @AtharccBot, the `telegram_links` table.
- `env.json` with `GROQ_API_KEY`.
- An Android phone, with usage access granted to Athar, and at least 3 days of normal use. For Telegram, an account that signed in with Telegram.

## Setup

1. Deploy the function: `npx supabase functions deploy send-report-telegram --no-verify-jwt --use-api`. It checks the caller's sign-in itself, and the existing secrets are reused.
2. Build: `flutter build apk --release --dart-define-from-file=env.json`, or `flutter run`.

## Scenarios

| # | Steps | Expected |
|---|---|---|
| 1 | Open Stats with usage access on | Real 7-day chart with weekday labels; top 5 apps match the phone's own Digital Wellbeing within ±10% (US1, SC-001) |
| 2 | Open Stats on web or with access off | Mock charts with a "Sample data" chip and Grant access (FR-003) |
| 3 | Fresh install, less than 3 days of data | "X more days to go", no Generate button (US2 #2) |
| 4 | Generate my report (the first time) | Consent dialog; Cancel produces no report, Continue produces a report with all 4 sections in under 15 s (US2 #1, FR-011) |
| 5 | Check the report | Every app named is in the top-apps list, and every prediction has a range (FR-006, SC-003) |
| 6 | Airplane mode, then Generate again after the cooldown | "Offline summary" report (FR-007, SC-004) |
| 7 | Tap Generate again within an hour | Disabled, with the time left (FR-009) |
| 8 | Kill and reopen the app, then open Stats | The latest report and its date are still there (FR-008) |
| 9 | Telegram account: Send to Telegram | Chart image plus text in the @AtharccBot chat in under 30 s (US3 #1, SC-005) |
| 10 | Email account: open a report | No Send to Telegram button (US3 #2, FR-013) |
| 11 | Block the bot, then Send | The "Unblock @AtharccBot" message (edge case) |

## Automated checks

- `flutter test`: `usage_insights` math (totals, top 5 with "Other", 4-hour blocks, forecast ranges, offline summary), plus the Groq reply validator (drops unknown apps, rejects bad JSON).
