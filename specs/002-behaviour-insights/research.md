# Research: Behaviour Insights & Predictions Report

Scope: academic demo, free tiers only. Builds on feature 001 (Supabase, @AtharccBot, `telegram_links`).

## R1. Per-app usage on Android

- **Decision**: add a `getAppUsage` method, taking `days` with a default of 7, to the existing `athar/device_usage` channel in `MainActivity.kt`. It builds foreground sessions from `UsageStatsManager.queryEvents` (`ACTIVITY_RESUMED` / `ACTIVITY_PAUSED`). For each app and local day, it returns the minutes in total and the minutes per hour (24 values). App names come from `PackageManager.getApplicationLabel`. Athar itself and the home launcher are left out.
- **Rationale**: `queryUsageStats(INTERVAL_DAILY)`, used today for the totals, has bucket edges that don't line up with local midnight and gives no time-of-day data. Events give exact sessions, which spec FR-005(c), "riskiest times of day", needs.
- **Alternatives**: `queryUsageStats` per day (no hourly profile); storing usage on Supabase (not needed, since nothing is sent automatically).
- **Risk**: some phones keep only a few days of events. Days with no data are returned as missing, not as zero (spec US1 #3). Needs testing on a real phone.

## R2. Charts

- **Decision**: reuse `WeekBarChart` and add an optional `labels` parameter (today it always shows `MockData.weekdays`).
  - Daily totals: 7 bars, labelled with real weekdays.
  - Time of day: the same widget with 6 bars of 4-hour blocks (0–4, 4–8 … 20–24).
  - Top apps: replace the mock data in `_AppBreakdown` with real data. The row layout stays.
- **Rationale**: no chart library; the widget is already styled and animated.
- **Alternative**: `fl_chart` (a new dependency for two bar charts).

## R3. Report generation: numbers in code, words from Groq

- **Decision**: the app computes all numbers itself (`lib/services/usage_insights.dart`, pure Dart):
  - daily totals, top apps, weekday vs weekend
  - the 4-hour profile and the peak blocks
  - the change against the first half of the period
  - the **forecast**: next week's total = mean daily × 7, with a range of ±1 standard deviation × √7; per app the same, for the top 3

  Groq gets only these aggregates and the onboarding goal (FR-012). It returns JSON (`response_format: json_object`) with `patterns[]`, `riskyTimes[]` and `suggestions[]`, plus short notes on each prediction.
- **Rationale**: predictions always have ranges and real numbers (FR-006, SC-003), and the model can't invent figures. Afterwards, the app drops any pattern that names an app missing from the data.
- **Client**: a new `BehaviourReportService` copies `GroqCoach`'s HTTP call: same key, model and endpoint, a 15 s timeout (FR-007), and `reasoning_effort: low`.
- **Offline fallback (FR-007)**: the same numbers, rendered from fixed templates ("Top app: X, 2h 10m/day", "Busiest day: Sat", "Screen time is up 12% vs the first half"). It's marked as offline.
- **Alternative**: send the raw sessions to the LLM (more tokens, more made-up numbers, more private data).

## R4. Keeping the latest report and the hourly limit

- **Decision**: store the latest report as JSON in `shared_preferences` (key `behaviour_report_v1`), with its `generatedAt`. Regenerating within 60 minutes just shows that report (FR-008, FR-009). The consent flag (FR-011) lives in `shared_preferences` too.
- **Rationale**: the report comes from data on this device, and the spec doesn't need it on other devices. `shared_preferences` is already a dependency.
- **Alternative**: a Supabase `reports` table (cross-device, but not required).

## R5. Send to Telegram

- **Decision**: a new Edge Function `send-report-telegram`, deployed with `--no-verify-jwt`. It verifies the caller itself with `auth.getUser(token)`, because the gateway check doesn't work well with the new publishable keys.
  1. Reads the caller from the JWT and requires `user.phone`, because only Telegram sign-in accounts qualify (FR-010, FR-013).
  2. Looks up `telegram_links.chat_id` for that phone, using the shared `db` helper.
  3. Calls `sendPhoto` (chart PNG, caption = title) and then `sendMessage` (report text, ≤ 4096 characters), both through the existing `_shared/telegram.ts`.
- **App side**: renders the daily-totals chart to a PNG with a `RepaintBoundary`, then calls `Supabase.instance.client.functions.invoke('send-report-telegram', body: {text, chartPngBase64})`. The button only shows when `currentUser.phone` is set.
- **Rationale**: the bot token stays on the server. JWT verification means only signed-in users can send, and only to their own linked chat.
- **Errors**: if the user blocked the bot, Telegram returns 403. The function returns `{error: "telegram_blocked"}`, and the app asks the user to unblock the bot (spec edge case).

## R6. Platforms

- Web and iOS have no per-app usage. `DeviceUsageService.readAppUsage` returns null there, Stats shows the existing mock data with a "Sample data" label (FR-003), and Generate explains that it needs the Android app.

## R7. Consent and privacy

- Before the first generation, a one-time dialog explains that app names, durations and times of day go to Groq. Cancelling means no report.
- The payload has no name, email or phone. The onboarding goal is sent as its label only ("Stop doomscrolling").
