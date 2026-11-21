Architecture
============

.. code-block:: text

   ┌──────────────── Flutter app (Android / iOS / web) ────────────────┐
   │ pages/ → components/ → atoms/   ·   services/   ·   models/       │
   └───────┬──────────────────────┬───────────────────┬────────────────┘
           │ supabase_flutter     │ http               │ MethodChannel
           ▼                      ▼                    ▼
   ┌─────────────── Supabase (free tier) ──┐   Groq API   Android
   │ Auth: email + phone OTP, sessions     │   (LLM)      UsageStatsManager
   │ Postgres: profiles, telegram_links    │              (MainActivity.kt)
   │ Edge Functions:                       │
   │   send-sms-telegram    (Auth hook)    │──┐
   │   telegram-webhook     (bot updates)  │  │ Bot API
   │   send-report-telegram (reports)      │  ├──────────▶ @AtharccBot
   └──────────┬────────────────────────────┘  │
              │ SMTP                           │
              ▼                                │
           Brevo ──▶ user's inbox     Telegram ◀┘

UI structure: atoms, components, pages
--------------------------------------

The interface follows a simplified **atomic design**, with three levels. Each
level uses only its own level or the ones below it: atoms import no
components or pages, and components import no pages.

.. list-table::
   :header-rows: 1
   :widths: 18 32 50

   * - Level
     - Folder
     - What's in it
   * - **Atoms**
     - ``lib/atoms/`` (10)
     - The smallest pieces, with no app logic: ``AppCard``, ``AppLogo``,
       ``BulletText``, ``CardTitle``, ``SectionTitle``, ``DeltaChip``,
       ``MetricIcon``, ``ProfileAvatar``, ``ProgressRing``,
       ``RoundIconButton``
   * - **Components**
     - ``lib/components/`` (25)
     - Pieces built from atoms, for example ``WeekBarChart``,
       ``ReportCard``, ``AppBreakdown``, ``BotLinkPanel``, ``ChatBubble``,
       ``HomeHeader``, ``QuestionPage``, ``PlanSummary``, ``OptionTile``
       and ``MetricTile``
   * - **Pages**
     - ``lib/pages/``
     - Full screens. They hold state, call services and navigate, and are
       assembled from components and atoms.

The refactor moved code without changing it. It was checked with pixel-level
screenshot comparisons of every screen (``test_screenshots/``) and the unit
tests after each step.

Layers and conventions
----------------------

* **Pages** are ``StatefulWidget`` classes using ``setState``. A move to
  MVVM is planned for later and is deliberately not part of these features.
* **Services** are static classes in ``lib/services/``, for example
  ``AuthService``, ``GroqCoach``, ``DeviceUsageService`` and
  ``BehaviourReportService``.
* **Pure logic** is kept apart from Flutter so it can be unit tested:
  ``usage_insights.dart`` (report math) and ``utils/phone.dart`` (phone
  normalization).
* **Server code** lives in ``supabase/functions/``, with shared helpers in
  ``_shared/`` (``phone.ts``, ``telegram.ts``).
* **Secrets:** the app ships only the Supabase URL, the publishable key and
  the Groq key. The bot token and the hook secrets live in Supabase's server
  secrets, and the Brevo SMTP key lives in the Supabase Auth settings.

Why these services
------------------

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Choice
     - Reason
   * - Supabase
     - Auth already handles code creation, expiry, rate limits and sessions.
       The free plan is enough for the demo, and it pauses after 7 idle days.
   * - Brevo
     - A free SMTP relay, plugged into Supabase as its custom email server.
   * - Telegram bot
     - Free. Telegram's own service for sending codes to any phone number is
       paid per message, so users share their number with the bot once
       instead.
   * - Groq
     - A fast, free tier for a reasoning LLM, already used by the coach.
