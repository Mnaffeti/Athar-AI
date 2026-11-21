# Contract: `athar/device_usage` → `getAppUsage`

New method on the existing channel in `android/app/src/main/kotlin/com/example/quit/MainActivity.kt`. The existing methods stay unchanged.

**Call**: `invokeListMethod('getAppUsage', {'days': 7})`

**Result**: a list of maps, one per (local day, app), for apps with more than 0 minutes:

```json
[
  {"date": "2026-11-20", "package": "com.instagram.android", "label": "Instagram",
   "minutes": 74.5, "hourly": [0,0,0,0,0,0,0,3.2,0,0,0,0,5,0,0,0,0,0,8,12,20,15,11.3,0]}
]
```

**Errors**: `USAGE_ACCESS_REQUIRED` when access isn't granted (same as `getTodayUsage`).

**Rules**:
- Sessions come from `ACTIVITY_RESUMED` → `ACTIVITY_PAUSED` / `ACTIVITY_STOPPED` events. A session still open at the end is closed at "now".
- A session that crosses an hour or midnight is split across the hours and days.
- Athar's own package and the default launcher are left out.
- Days with no events at all are absent. Dart treats them as "no data", not as 0.
