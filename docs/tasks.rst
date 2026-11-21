Tasks and their status
======================

The full task lists are ``specs/001-otp-auth/tasks.md`` and
``specs/002-behaviour-insights/tasks.md``. Each task has an ID, an optional
``[P]`` (can run in parallel) and a user-story label (``[US1]``…).

Feature 001: OTP sign-in (23 of 26 done)
------------------------------------------

.. raw:: html
   :file: _static/charts/tasks_001.svg

Hover a bar for its count. The only open tasks are the three polish tasks.

.. list-table::
   :header-rows: 1
   :widths: 18 12 70

   * - Phase
     - Tasks
     - Content
   * - Setup
     - T001–T003
     - ``supabase_flutter`` and ``url_launcher``, ``supabase init``,
       Android/iOS link permissions
   * - Foundation
     - T004–T009
     - Database migration, Supabase init, profile JSON, ``AuthService``, the
       code-entry screen
   * - US1 Email (MVP)
     - T010–T013
     - Email send and verify, the sign-in screen, saving the plan, Brevo setup
   * - US2 Telegram
     - T014–T021
     - Phone normalization (Dart and TypeScript, with tests), the two server
       functions, the Telegram UI, the bot setup
   * - US3 Session
     - T022–T023
     - Open on the home screen when signed in, real sign-out
   * - Polish (open)
     - T024–T026
     - Remove leftover demo code, then a final analysis and device run

Feature 002: Behaviour insights (18 of 18 done)
-------------------------------------------------

.. raw:: html
   :file: _static/charts/tasks_002.svg

.. list-table::
   :header-rows: 1
   :widths: 18 12 70

   * - Phase
     - Tasks
     - Content
   * - Setup
     - T001
     - Share the Groq settings with ``GroqCoach``
   * - Foundation
     - T002–T005
     - Models, chart labels, the insights math and its tests
   * - US1 Charts (MVP)
     - T006–T008
     - Android ``getAppUsage``, ``readAppUsage``, real data on Stats
   * - US2 Report
     - T009–T012
     - The report service (Groq, validation, storage, cooldown, consent),
       tests, the report screen, the report card
   * - US3 Telegram
     - T013–T016
     - The ``send-report-telegram`` function, the app-side send, the button,
       deployment
   * - Polish
     - T017–T018
     - The README, analysis, tests and the APK build

Still to verify on a device: real Android usage data, live Groq replies, and
the Telegram send (``quickstart.md`` scenarios 1–11).

Tests
-----

22 automated Flutter tests, all passing. Most of them cover the report math
and the AI-reply checks, where a mistake would show the user wrong numbers.

.. raw:: html
   :file: _static/charts/tests.svg

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - File
     - What it checks
   * - ``test/onboarding_answers_test.dart``
     - The profile JSON round-trip
   * - ``test/phone_test.dart``
     - Normalizing phone numbers to the international (E.164) format
   * - ``test/auth_errors_test.dart``
     - A server error isn't shown as "offline"
   * - ``test/usage_insights_test.dart``
     - Totals, top 5 plus Other, blocks, forecast ranges, the offline
       report, the sample data
   * - ``test/behaviour_report_test.dart``
     - LLM reply validation, the cooldown, the Telegram text
   * - ``test/widget_test.dart``
     - Splash to welcome to quiz, all tabs render, the profile opens
   * - ``supabase/functions/_shared/phone_test.ts``
     - Server-side phone normalization and the own-contact check (Deno)
