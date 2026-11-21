# Feature Specification: Behaviour Insights & Predictions Report

**Feature Branch**: `002-behaviour-insights`

**Created**: 2026-11-21

**Status**: Draft

**Input**: User description: "Behaviour analysis and predictions: analyse the user's screen time per app, show charts, use Groq LLMs to produce behaviour insights and predictions, and deliver the final report in the app or send it to the user's Telegram."

## Clarifications

### Session 2026-11-21

- Q: Can email-only accounts link Telegram just to receive reports? → A: No. Telegram delivery is only for accounts that signed in with Telegram.
- Q: Is the automatic weekly report in scope? → A: No. Only the on-demand Send to Telegram button.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See my real screen time per app in charts (Priority: P1)

A signed-in user opens the Stats tab and sees their real screen time from the last 7 days: total time per day as a bar chart, and their top apps ranked by time, each with its share of the total. Today the per-app list shows sample data; this story replaces it with the user's own usage.

**Why this priority**: Every insight and prediction is built on this data. On its own, it already gives the user an honest picture of their habits.

**Independent Test**: On an Android phone with usage access granted, use two apps for a known time, open Stats, and confirm both apps appear with roughly the right durations, and that the 7-day chart shows today's total.

**Acceptance Scenarios**:

1. **Given** usage access is granted, **When** the user opens Stats, **Then** they see a 7-day daily total chart and their top 5 apps with time and share of the total, taken from their own device.
2. **Given** usage access is not granted, **When** the user opens Stats, **Then** they see a clear prompt to grant it, and the charts are labelled as sample data until they do.
3. **Given** fewer than 7 days of usage exist, **When** the user opens Stats, **Then** the chart shows the days available, and missing days are empty, not zero.

---

### User Story 2 - Get an AI behaviour report with predictions (Priority: P2)

From Stats, the user taps **Generate my report**. Within seconds they get a report that:
- **Explains their patterns**, for example "most of your Instagram time happens after 22:00" or "weekends are 40% higher than weekdays".
- **Predicts next week**: total screen time and the top 3 apps, each with an expected range.
- **Flags risky moments**, i.e. the times of day when they're most likely to overuse.
- **Gives 3 concrete suggestions** tied to their goal from onboarding.

The report shows the charts next to the text, so the user can see the evidence behind each statement.

**Why this priority**: This is the core value the user asked for, turning raw numbers into understanding and a forecast. It needs Story 1's data.

**Independent Test**: With at least 3 days of usage, generate a report and confirm it has all four parts, mentions only apps that appear in the data, and gives predictions as ranges with a stated confidence.

**Acceptance Scenarios**:

1. **Given** at least 3 days of usage, **When** the user taps Generate my report, **Then** a report with patterns, predictions, risky moments and suggestions appears within 15 seconds.
2. **Given** fewer than 3 days of usage, **When** the user taps Generate my report, **Then** they're told how many more days are needed, and no report is generated.
3. **Given** the AI service is unavailable, **When** the user generates a report, **Then** they still get the charts plus a simple rule-based summary (top app, busiest day, week-over-week change), clearly marked as offline.
4. **Given** a report was generated, **When** the user reopens Stats later, **Then** their latest report is still there, with the date it was generated.

---

### User Story 3 - Receive the report on Telegram (Priority: P3)

A user who signed in with Telegram taps **Send to Telegram** on a report, and the same report (text plus the main chart as an image) arrives in their chat with the Athar bot.

**Why this priority**: It's a convenience channel on top of Story 2. It reuses the Telegram link the user already made when signing in.

**Independent Test**: As a user who signed in with Telegram, tap Send to Telegram, and confirm the bot delivers the report text and chart within 30 seconds.

**Acceptance Scenarios**:

1. **Given** a user who signed in with Telegram, **When** they tap Send to Telegram, **Then** the report text and chart arrive in their bot chat, and the app confirms it was sent.
2. **Given** a user who signed in with email, **When** they view a report, **Then** no Send to Telegram button is shown; the report is available in the app only.

---

### Edge Cases

- **Data source:** the user is on web or iPhone, where per-app usage can't be read. Stats shows sample data with a clear label, and generating a report explains that real reports need the Android app.
- **Tiny usage days:** apps used for under 1 minute in total are grouped as "Other" in the charts and the report.
- **Prediction honesty:** the AI must not invent apps, numbers or dates that aren't in the data. Any figure that isn't in the data is presented as a prediction with a range.
- **Many apps:** only the top 5 are named in charts; the rest are grouped as "Other".
- **The user blocked the bot:** Send to Telegram fails with a message asking them to unblock it, and the report stays available in the app.
- **Repeated taps:** a new report can be generated at most once per hour. Tapping again within the hour shows the latest report.
- **Time zones:** "day" and "time of day" use the phone's local time zone.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST collect the user's daily screen time per app for the last 7 days from their device, when they've granted usage access.
- **FR-002**: The Stats screen MUST show a 7-day daily total chart and a ranked list of the top 5 apps (time and percentage of total), with everything else grouped as "Other".
- **FR-003**: When real usage data is not available, the Stats screen MUST label all charts as sample data and explain how to get real data.
- **FR-004**: Users MUST be able to generate a behaviour report on demand with at least 3 days of usage.
- **FR-005**: Each report MUST contain:
  - (a) 2–4 observed patterns, each tied to a number from the data
  - (b) a prediction for next week's total screen time and top 3 apps, each with a range
  - (c) the 1–2 riskiest times of day
  - (d) 3 suggestions linked to the user's onboarding goal
- **FR-006**: Reports MUST only name apps that appear in the user's data, and MUST present predictions as estimates with a range, never as facts.
- **FR-007**: If the AI service fails or times out (15 s), the system MUST show a rule-based summary instead, marked as offline: top app, busiest day, and week-over-week change.
- **FR-008**: The latest report MUST be kept and shown again on later visits, with its generation date.
- **FR-009**: Report generation MUST be limited to once per hour per user.
- **FR-010**: Users who signed in with Telegram MUST be able to send a report to their Athar bot chat as text plus the main chart image.
- **FR-011**: Before the first report, the system MUST tell the user that a summary of their app usage (app names and durations, no message content) is sent to an AI service to write the report, and MUST let them cancel.
- **FR-012**: Data sent to the AI service MUST contain only app names, durations, times of day and the onboarding goal. It MUST NOT include the user's email, phone number or name.
- **FR-013**: Email-only accounts MUST NOT be offered Telegram delivery, and no report is ever sent automatically; sending happens only when the user taps Send to Telegram.

### Key Entities

- **Daily App Usage**: one app's total foreground time for one local day, for one user. Fields: date, app name, minutes, and a usage-by-hour profile.
- **Behaviour Report**: one generated report. Fields: generation time, period covered, patterns, predictions (value + range + confidence), risky times, suggestions, source (AI or offline), and whether it was sent to Telegram.
- **Telegram Link**: reused from the sign-in feature. It connects an account's phone number to the user's Athar bot chat.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users with usage access see their real top apps and 7-day chart within 3 seconds of opening Stats.
- **SC-002**: 95% of report requests return a complete report (all four parts) within 15 seconds.
- **SC-003**: In a review of 20 generated reports, 100% name only apps present in the data, and every prediction includes a range.
- **SC-004**: When the AI service is unavailable, users still get a report (the offline summary) in 100% of attempts.
- **SC-005**: Reports sent to Telegram arrive within 30 seconds in 95% of attempts.
- **SC-006**: Over a 2-week pilot, at least 60% of users who generate a report rate it as "useful" or better.

## Assumptions

- Real per-app usage is available only in the Android app, which already has a usage-access permission flow. Web and iOS show sample data.
- Android keeps enough daily history to cover the last 7 days, so the feature needs no backfill from a server.
- The AI provider is the Groq service the coach already uses. Its free tier is enough for a demo, at about one report per user per hour.
- Predictions are simple forecasts from 3–7 days of history. They are meant as guidance, not exact numbers.
- Telegram delivery reuses the existing @AtharccBot and phone-number links from feature 001. Scheduled or weekly automatic reports are out of scope.
- Report language is English, like the rest of the app.
