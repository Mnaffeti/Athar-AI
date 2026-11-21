# Contract: Groq report request (from `BehaviourReportService`)

Same endpoint, key and model as `GroqCoach` (`lib/services/groq_coach.dart`). `temperature: 0.4`, `reasoning_effort: low`, `response_format: {"type": "json_object"}`, timeout 15 s.

## User message (aggregates only, FR-012)

```json
{
  "goal": "Stop doomscrolling",
  "days": 7,
  "daily_minutes": {"Mon": 260, "Tue": 231, "...": 0},
  "top_apps": [{"app": "Instagram", "min_per_day": 74, "share_pct": 31}],
  "blocks_min_per_day": {"0-4": 5, "4-8": 2, "8-12": 30, "12-16": 41, "16-20": 60, "20-24": 98},
  "weekday_avg": 220, "weekend_avg": 310, "change_pct": 12,
  "forecast_week_minutes": {"total": {"mean": 1680, "low": 1420, "high": 1940},
                            "Instagram": {"mean": 520, "low": 410, "high": 630}}
}
```

## Expected JSON reply

```json
{
  "patterns": ["2–4 sentences, each citing a number from the input"],
  "prediction_notes": {"total": "one short sentence", "Instagram": "..."},
  "risky_times": ["1–2 items, e.g. '20:00–24:00: 98 min/day, mostly Instagram'"],
  "suggestions": ["exactly 3, tied to the goal"]
}
```

## The app validates the reply

- Not JSON, a missing key, or the wrong counts → offline report.
- Patterns or risky times that name an app not in `top_apps` are dropped.
- Prediction numbers are always taken from `forecast`. The model only adds the notes.
