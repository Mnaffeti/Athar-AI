Architecture
============

.. code-block:: text

   ┌──────────────── Flutter app (Android / iOS / web) ────────────────┐
   │ screens/ (setState)  →  services/ (static classes)  →  models/    │
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

Layers and conventions
----------------------

* **Screens** are ``StatefulWidget`` classes using ``setState``. A move to
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
