# Implementation Plan: Behaviour Insights & Predictions Report

**Branch**: `002-behaviour-insights` | **Date**: 2026-11-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-behaviour-insights/spec.md`

## Summary

Turn the Stats tab from mock data into the user's real per-app screen time, and add an AI report.
1. **Data**: the existing Android usage channel gets a `getAppUsage` method that returns per-app, per-hour minutes for the last 7 days.
2. **Numbers**: a pure-Dart `usage_insights.dart` computes totals, top apps, time-of-day blocks and a forecast with ranges.
3. **Words**: Groq, called the way `GroqCoach` already calls it, turns those aggregates into patterns, risky times and suggestions. If Groq fails, a rule-based offline summary takes its place.
4. **Charts**: the existing `WeekBarChart` gains custom labels.
5. **Storage**: the latest report is kept in `shared_preferences`.
6. **Telegram**: users who signed in with Telegram can send the report through a new JWT-protected Edge Function that reuses the bot and `telegram_links`.

## Technical Context

**Language/Version**: Dart ^3.9.2 / Flutter; Kotlin (Android channel); TypeScript on Deno (Edge Function)

**Primary Dependencies**: existing only: `http` (Groq), `shared_preferences`, `supabase_flutter` (`functions.invoke`), Android `UsageStatsManager`; Telegram Bot API through `supabase/functions/_shared/telegram.ts`

**Storage**: `shared_preferences` for the latest report, the consent flag and the cooldown. No new database tables.

**Testing**: `flutter test` for the insights math and the Groq reply validation; a real Android phone for usage data ([quickstart.md](quickstart.md))

**Target Platform**: Android for real data; web and iOS show labelled sample data

**Project Type**: mobile app plus one serverless function

**Performance Goals**: Stats under 3 s, report under 15 s, Telegram delivery under 30 s (SC-001, SC-002, SC-005)

**Constraints**: $0/month (Groq and Supabase free tiers); only aggregates go to Groq (FR-012); the bot token never ships in the app

**Scale/Scope**: demo. 1 Kotlin method, 3 new Dart files, 2 changed widgets or screens, 1 new report screen, 1 Edge Function

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template, so there are no gates. **Pass.** Post-design: same. The design follows existing patterns: static services in `lib/services/`, `setState` screens, `_shared` helpers for functions.

## Project Structure

### Documentation (this feature)

```text
specs/002-behaviour-insights/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── android-usage-channel.md
│   ├── groq-report.md
│   ├── send-report-telegram.md
│   └── stats-ui.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
android/app/src/main/kotlin/com/example/quit/MainActivity.kt   # + getAppUsage
lib/
├── models/app_usage.dart                 # NEW: AppUsageDay, BehaviourReport (+ JSON)
├── services/device_usage_service.dart    # + readAppUsage()
├── services/usage_insights.dart          # NEW: pure aggregation, forecast, offline summary
├── services/behaviour_report_service.dart# NEW: Groq call, validation, save/load, cooldown, Telegram send
├── widgets/bar_chart.dart                # + optional labels
└── screens/stats/
    ├── stats_screen.dart                 # real data, "Sample data" chip, report card
    └── report_screen.dart                # NEW
supabase/functions/send-report-telegram/index.ts   # NEW (JWT on)
test/
├── usage_insights_test.dart
└── behaviour_report_test.dart
```

**Structure Decision**: same layout as feature 001: the app under `lib/` and server code under `supabase/functions/`, reusing `_shared/phone.ts` and `_shared/telegram.ts`.

## Complexity Tracking

No violations. Choices, kept deliberately small:

| Choice | Why | Simpler or bigger option rejected |
|---|---|---|
| Forecast computed in Dart, not by the LLM | Guarantees real numbers and ranges (FR-006) | Asking the LLM to predict (it may invent numbers) |
| Report stored on the device | No cross-device need in the spec | A Supabase table (unneeded backend work) |
| Reuse `WeekBarChart` | Already styled and animated | Adding a chart library |
