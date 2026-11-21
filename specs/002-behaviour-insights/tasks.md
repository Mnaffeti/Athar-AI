# Tasks: Behaviour Insights & Predictions Report

**Input**: Design documents from `/specs/002-behaviour-insights/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: The unit tests listed in plan.md and quickstart.md (insights math, Groq reply validation). Device and Telegram checks are manual, per quickstart.md.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no unfinished dependency)
- **[Story]**: US1 = real charts, US2 = AI report, US3 = Send to Telegram

---

## Phase 1: Setup

No new dependencies or project setup. Feature 001 already provides Supabase, the bot and `telegram_links`.

- [X] T001 Confirm `GROQ_API_KEY` is in env.json and that `lib/services/groq_coach.dart` exposes nothing the new service needs to share. Make `GroqCoach`'s endpoint, model and key `static const` members reusable, without duplicating the values, in lib/services/groq_coach.dart

---

## Phase 2: Foundational (blocks all stories)

- [X] T002 [P] Create lib/models/app_usage.dart with `AppUsageDay(date, package, label, minutes, hourly)` (`fromMap`) and `BehaviourReport` (fields per data-model.md, `toJson`/`fromJson`, and a `Prediction(subject, mean, low, high, note)` record)
- [X] T003 [P] Add an optional `List<String>? labels` to `WeekBarChart` in lib/widgets/bar_chart.dart. Use `labels![i]` when it's given, otherwise keep `MockData.weekdays[i % 7]`
- [X] T004 Create lib/services/usage_insights.dart: pure functions over `List<AppUsageDay>` that return a `UsageSummary`:
  - `dailyTotals` (date → minutes, missing days absent)
  - top 5 apps with share %, everything else and apps under 1 minute in total going to "Other"
  - 6 four-hour blocks as average minutes per day
  - `weekdayAvg`, `weekendAvg`, and `changePct` (2nd half vs 1st half)
  - `forecast` for the total and the top 3 apps: mean = average × 7, range = ±1 SD × √7, low clamped at 0
  - `offlineReport(summary)`, which builds a `BehaviourReport(source: offline)`
- [X] T005 [P] Unit tests in test/usage_insights_test.dart: totals, top 5 plus Other, block averages, forecast range (and low ≥ 0), changePct, and offline report wording with 3 days of fixture data

**Checkpoint**: data types, chart labels and all the math are ready and tested.

---

## Phase 3: User Story 1 - Real screen time per app in charts (P1) 🎯 MVP

**Goal**: Stats shows the user's real 7-day totals and top 5 apps on Android, and labelled sample data elsewhere.

**Independent test**: quickstart scenarios 1–2.

- [X] T006 [US1] Add a `getAppUsage(days)` handler to android/app/src/main/kotlin/com/example/quit/MainActivity.kt, per contracts/android-usage-channel.md:
  - `queryEvents` over the last N local days, pairing `ACTIVITY_RESUMED` with `ACTIVITY_PAUSED`/`ACTIVITY_STOPPED`
  - split sessions across hours and days, and close any open session at now
  - leave out our own package and the default launcher (`resolveActivity` of `Intent.CATEGORY_HOME`)
  - labels from `PackageManager.getApplicationLabel`, falling back to the package name
  - return a list of maps, or `USAGE_ACCESS_REQUIRED` when access is off
- [X] T007 [US1] Add `static Future<List<AppUsageDay>?> readAppUsage({int days = 7})` to lib/services/device_usage_service.dart. It returns null on web, on `MissingPluginException`, or when access is denied
- [X] T008 [US1] In lib/screens/stats/stats_screen.dart:
  - in `initState`, load `readAppUsage()` and build the `UsageSummary`
  - when there's data, give the screen-time `WeekBarChart` the real daily totals (hours) with real weekday labels, and give `_AppBreakdown` the real top 5 plus "Other"
  - when there's no data, keep the mock charts, add a "Sample data" chip, and show a "Grant usage access" button on Android (`DeviceUsageService.openUsageAccessSettings`)
  - refresh when the app resumes

**Checkpoint**: Stats shows real data on an Android phone.

---

## Phase 4: User Story 2 - AI behaviour report with predictions (P2)

**Goal**: on-demand report with patterns, predictions with ranges, risky times and 3 suggestions; offline fallback; saved and limited to once per hour.

**Independent test**: quickstart scenarios 3–8.

- [X] T009 [US2] Create lib/services/behaviour_report_service.dart:
  - `generate(summary, goal)`: build the aggregate JSON (contracts/groq-report.md, with no name, email or phone), POST to Groq with `response_format: json_object`, a 15 s timeout and `reasoning_effort: low`, validate the reply, and fall back to `offlineReport` on any failure
  - `validate(reply, summary)` (public, for tests): require the keys and counts, drop patterns and risky times that name apps not in the top apps, and always take the prediction numbers from `summary.forecast`
  - `loadLatest()` / `save(report)` in shared_preferences (`behaviour_report_v1`)
  - `cooldownLeft()`, from `generatedAt` (60 min)
  - `hasConsent()` / `giveConsent()` (`behaviour_report_consent`)
- [X] T010 [P] [US2] Unit tests in test/behaviour_report_test.dart: `validate` drops an unknown app, rejects a reply missing a key or with the wrong count of suggestions, and keeps the forecast numbers. JSON round-trip of `BehaviourReport`
- [X] T011 [US2] Create lib/screens/stats/report_screen.dart, per contracts/stats-ui.md:
  - header with the period and an "Offline summary" chip
  - Patterns, then Next week (predictions as `~Xh (low–high h)` plus the note, then the daily `WeekBarChart` inside a `RepaintBoundary` with a GlobalKey), then Risky times (the 6-block `WeekBarChart` labelled `0-4 … 20-24`), then Suggestions
- [X] T012 [US2] Add a "Your report" card to lib/screens/stats/stats_screen.dart:
  - fewer than 3 days of data: "X more days to go"
  - otherwise **Generate my report**, with the consent dialog on first use; Cancel stops
  - a loading state while generating; when done, push ReportScreen
  - with a saved report: its date, **View report**, and **Generate again**, disabled while `cooldownLeft()` > 0 with the minutes shown
  - on web or iOS with no real data, explain that real reports need the Android app

**Checkpoint**: reports generate, fall back offline, persist and respect the cooldown.

---

## Phase 5: User Story 3 - Send the report to Telegram (P3)

**Goal**: users who signed in with Telegram send the report (chart image plus text) to their bot chat.

**Independent test**: quickstart scenarios 9–11.

- [X] T013 [P] [US3] Create supabase/functions/send-report-telegram/index.ts, per contracts/send-report-telegram.md:
  - JWT verification on; get the user with `db.auth.getUser(token)`
  - no `user.phone` → 403 `not_telegram_account`
  - `normalizeE164` and a lookup of `telegram_links.chat_id` → 404 `telegram_not_linked`
  - optional `sendPhoto` as multipart (base64 PNG, ≤ 5 MB) with the caption "Your Athar report", then `sendMessage(text ≤ 4000)`
  - a Telegram 403 → 409 `telegram_blocked`; other failures → 502
  - add a `sendTelegramPhoto` helper to supabase/functions/_shared/telegram.ts
- [X] T014 [US3] Add `sendToTelegram(report, pngBytes)` to lib/services/behaviour_report_service.dart: format the report as plain text, call `Supabase.instance.client.functions.invoke('send-report-telegram', body: {...})`, map `FunctionException` errors to `not_linked`, `blocked` and `failed`, and set `sentToTelegramAt` and save on success
- [X] T015 [US3] In lib/screens/stats/report_screen.dart, show a **Send to Telegram** button only when `Supabase.instance.client.auth.currentUser?.phone` is non-empty. Capture the chart with `RepaintBoundary.toImage(pixelRatio: 2)` as a PNG, call `sendToTelegram`, show a spinner and then "Sent to Telegram", and show the error messages from contracts/stats-ui.md
- [X] T016 [US3] Deploy: `npx supabase functions deploy send-report-telegram --use-api` (needs the owner's OK), and document it in supabase/README.md

**Checkpoint**: Telegram users receive the report in their bot chat.

---

## Phase 6: Polish

- [X] T017 [P] Update README.md: the Stats/Report feature, the Android usage access step, and the note that only aggregates go to Groq
- [X] T018 Run `flutter analyze`, `flutter test` and `flutter build apk --release --dart-define-from-file=env.json`, then walk through quickstart.md 1–11 (the device scenarios once an Android phone is available)

---

## Dependencies & Execution Order

- T001 → Foundational (T002–T005) → the stories.
- **US1 (T006–T008)**: needs T002, T003 and T004. It's the MVP and needs Android to see real data.
- **US2 (T009–T012)**: needs T004. Its UI can be tested in Chrome using the offline report and sample data only after T008 adds the data path, so do US1 first.
- **US3 (T013–T016)**: needs T011 (report screen) and T009. T013 can be built in parallel with US2.
- **Polish** last.

## Parallel Examples

- Foundational: T002, T003 and T005 together (T005 is written against T004's API, which T004 then implements).
- US2: T010 alongside T011.
- US3: T013 (server) alongside T009–T012 (app).

## Implementation Strategy

1. **MVP**: T001–T008, giving real charts on Android.
2. **Report**: T009–T012, giving the AI report, the offline fallback and persistence.
3. **Telegram**: T013–T016.
4. **Polish**: T017–T018.
