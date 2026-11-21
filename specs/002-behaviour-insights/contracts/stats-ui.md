# Contract: Stats screen and report UI

## Stats screen (`lib/screens/stats/stats_screen.dart`)

- **On open**: if `DeviceUsageService.readAppUsage()` returns data, show the following. Otherwise keep the mock charts with a **"Sample data"** chip, and a **Grant usage access** button on Android (FR-003).
  - the real 7-day `WeekBarChart`, with real weekday labels
  - the real top 5 apps (`_AppBreakdown`)
- **"Your report" card**:

| State | Shows |
|---|---|
| fewer than 3 days of data | "Report needs 3 days of data. X more to go." |
| ready, no report yet | **Generate my report** |
| a report exists | the date, "View report" and **Generate again** (disabled for up to 1 h, with the time left) |

## Report screen (`lib/screens/stats/report_screen.dart`, new)

Sections, in order:
1. A header with the period, plus an "Offline summary" chip if the report is offline.
2. **Patterns**: 2–4 bullets.
3. **Next week**: the predictions, as "~28h (24–32h)" with a note. Underneath, the daily totals chart, wrapped in a `RepaintBoundary` so it can be exported.
4. **Risky times**: 1–2 items, with the 6-block time-of-day chart.
5. **Suggestions**: 3 bullets.
6. **Send to Telegram**: only if `currentUser.phone` is set. It shows a spinner while sending, then "Sent to Telegram". Error messages:

| Error | Message |
|---|---|
| not linked | "Your number isn't linked to the Athar bot. Open Telegram, start @AtharccBot and share your number." |
| blocked | "Unblock @AtharccBot in Telegram, then try again." |
| other | "Couldn't send right now. Your report is still saved here." |

**Consent dialog** (first generation only): "To write your report, Athar sends app names, minutes and times of day to Groq's AI. No name, email or phone." Buttons: **Continue** / **Cancel**.
