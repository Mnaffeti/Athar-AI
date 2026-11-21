Feature 002: Behaviour insights and predictions
================================================

**Spec folder:** ``specs/002-behaviour-insights/`` · **Status:** implemented,
waiting for testing on a real Android phone

What it does
------------

1. **Real charts (US1):** on Android, the Stats tab shows the last 7 days of
   real screen time (a daily chart) and the top 5 apps plus "Other". On web
   and iOS, it shows labelled **sample data**.
2. **AI report (US2):** **Generate my report** produces:

   * patterns, each tied to a number from the data
   * next week's forecast, for the total and the top 3 apps, each with a
     range
   * the riskiest times of day
   * 3 suggestions tied to the user's goal

   If Groq fails or takes over 15 s, an **offline summary** is used instead.
   The latest report is kept, and a new one can be made once an hour. A
   consent dialog appears before the first report.

3. **Send to Telegram (US3):** accounts that signed in with Telegram can send
   the chart image and the text to @AtharccBot.

Numbers from code, words from the LLM
-------------------------------------

The key design decision (``research.md`` R3): **every number is computed
in Dart**, by ``lib/services/usage_insights.dart``:

* daily totals, the top 5 apps with their shares, and six 4-hour blocks
* weekday vs weekend, and the change between the two halves of the period
* the forecast: next week = mean × 7, with a range of ±1 SD × √7, never
  below 0

Groq receives only those aggregates, and writes the sentences as JSON.
``BehaviourReportService.validate`` then:

* rejects replies with missing keys or too few items
* drops sentences that name apps absent from the data
* always takes the prediction numbers from the forecast, never from the
  model

So the AI can't invent figures, and every prediction has a range.

What the report charts look like
--------------------------------

These are the charts the report shows, drawn from the app's **sample data**
(the preview available on web): the demo apps, busier weekends, and evenings
as the peak. They are computed with the same formulas as the app.

.. raw:: html
   :file: ../_static/charts/sample_daily.svg

*Screen time per day.* Saturday and Sunday are the busiest days.

.. raw:: html
   :file: ../_static/charts/sample_blocks.svg

*Time of day.* 20:00–24:00 is the riskiest block, at 62 min a day, which
becomes the report's "risky time".

.. raw:: html
   :file: ../_static/charts/sample_forecast.svg

*Next week's forecast.* The dot is the expected value and the light bar is
the range (±1 SD × √7). Every prediction is shown with a range, never as a
single exact number.

.. list-table:: Sample forecast (table view of the chart above)
   :header-rows: 1
   :widths: 30 35 35

   * - Subject
     - Expected next week
     - Range
   * - Total
     - 16.2h
     - 15.1–17.3h
   * - YouTube
     - 6.9h
     - 6.5–7.4h
   * - Instagram
     - 4.2h
     - 3.9–4.5h
   * - TikTok
     - 3.1h
     - 2.9–3.3h

Main files
----------

.. list-table::
   :header-rows: 1
   :widths: 45 55

   * - File
     - Role
   * - ``android/.../MainActivity.kt`` (``getAppUsage``)
     - Builds per-app, per-hour sessions from ``UsageStatsManager`` events
   * - ``lib/services/device_usage_service.dart``
     - ``readAppUsage()``, which returns null on web, iOS or without access
   * - ``lib/models/app_usage.dart``
     - ``AppUsageDay``, ``Prediction``, ``BehaviourReport`` (as JSON)
   * - ``lib/services/usage_insights.dart``
     - Pure math, the forecast and the offline report
   * - ``lib/services/behaviour_report_service.dart``
     - The Groq call, validation, storage, cooldown, consent and the Telegram
       send
   * - ``lib/screens/stats/stats_screen.dart``, ``report_screen.dart``
     - Charts, the "Your report" card and the report view
   * - ``lib/widgets/bar_chart.dart``
     - ``WeekBarChart``, which gained custom labels
   * - ``supabase/functions/send-report-telegram/index.ts``
     - Checks the caller's sign-in, then sends the photo and text to their
       linked chat
