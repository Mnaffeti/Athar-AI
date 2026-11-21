# Data Model: Behaviour Insights

Everything lives on the device; no new database tables. Reused from feature 001: `telegram_links(phone → chat_id)`.

## AppUsageDay (from the Android channel)

| Field | Type | Rules |
|---|---|---|
| `date` | `yyyy-MM-dd` | local day; only days with data are present |
| `package` | string | e.g. `com.instagram.android` |
| `label` | string | app name shown to the user |
| `minutes` | double ≥ 0 | foreground minutes that day |
| `hourly` | 24 doubles | minutes per local hour; they sum to `minutes` |

## UsageSummary (computed in `usage_insights.dart`)

| Field | Notes |
|---|---|
| `days` | number of days with data (3–7 are needed for a report) |
| `dailyTotals` | date → minutes, for the chart |
| `topApps` | top 5 by minutes per day, with share %; the rest → "Other" (apps under 1 minute total also → "Other") |
| `blocks` | 6 × 4-hour block averages (minutes per day), for the chart and the risky times |
| `weekdayAvg`, `weekendAvg` | minutes per day |
| `changePct` | 2nd half of the period vs the 1st half |
| `forecast` | `total` and the top 3 apps, each `{mean, low, high}` minutes per week |

## BehaviourReport (stored as JSON in shared_preferences)

| Field | Notes |
|---|---|
| `generatedAt` | ISO time; drives the "once per hour" limit |
| `periodStart`, `periodEnd` | dates covered |
| `patterns[]` | 2–4 strings; any that name an unknown app are dropped |
| `predictions[]` | `{subject, mean, low, high, note}`; the numbers always come from `forecast` |
| `riskyTimes[]` | 1–2 strings |
| `suggestions[]` | exactly 3 strings |
| `source` | `ai` or `offline` |
| `dailyTotals`, `blocks` | chart data kept with the report, so it renders the same when reopened |
| `sentToTelegramAt` | null until sent |

## States

```text
No usage access ─grant─▶ Collecting (<3 days) ─3+ days─▶ Ready
Ready ─Generate─▶ (consent once) ─▶ Generating ─ok─▶ Report(ai)
                                              └fail/15 s─▶ Report(offline)
Report ─Send to Telegram (phone accounts only)─▶ Sent | Error(not linked / blocked)
```
