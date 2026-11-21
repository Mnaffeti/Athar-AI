What the app includes
=====================

Athar runs on Android, iOS and the web, from one Flutter code base. The table
lists every part of the app and where its code lives.

.. list-table::
   :header-rows: 1
   :widths: 22 48 30

   * - Part
     - What the user gets
     - Code
   * - Splash and welcome
     - Brand splash, then a welcome screen with **Get started** and
       **Log in with OTP**. Signed-in users go straight to the home screen.
     - ``lib/pages/splash_screen.dart``,
       ``lib/pages/onboarding/welcome_screen.dart``
   * - Onboarding quiz and plan
     - A short quiz (name, age, height, weight, goal, worst apps, gym
       frequency, phone-free goal) that produces a personal plan.
     - ``lib/pages/onboarding/quiz_screen.dart``,
       ``plan_screen.dart``, ``lib/models/onboarding_answers.dart``
   * - Sign-in (feature 001)
     - One-time 6-digit codes by **email** or **Telegram**. Sign-up and login
       are the same flow, and the session lasts until sign-out.
     - ``lib/pages/auth/``, ``lib/services/auth_service.dart``,
       ``supabase/``. See :doc:`features/auth`.
   * - Home
     - A greeting with the date, today's metrics and progress rings.
     - ``lib/pages/home/home_screen.dart``
   * - Track
     - Daily screen time, scrolling, social media, gym and phone-free time.
       On Android, totals come from the phone's usage statistics.
     - ``lib/pages/tracking/``, ``lib/services/tracking_service.dart``,
       ``device_usage_service.dart``
   * - Stats and AI report (feature 002)
     - A 7-day chart, the top apps, and an AI behaviour report with
       patterns, a forecast for next week, risky times and suggestions. It
       can be sent to Telegram.
     - ``lib/pages/stats/``, ``lib/services/usage_insights.dart``,
       ``behaviour_report_service.dart``. See :doc:`features/insights`.
   * - AI coach
     - A chat coach powered by Groq that knows the user's plan.
     - ``lib/pages/coach/``, ``lib/services/groq_coach.dart``
   * - Profile
     - Body stats, goals, settings and **Sign out**.
     - ``lib/pages/profile/profile_screen.dart``
   * - Reminders
     - Local notifications to nudge phone-free time (not on web).
     - ``lib/services/notification_service.dart``

Data the app keeps
------------------

* **On Supabase:** the account (email *or* phone), the ``profiles`` row
  holding the onboarding answers, and ``telegram_links``, which maps a phone
  number to its Telegram chat.
* **On the device:** the session, the latest behaviour report, the report
  consent flag, and notification settings.
* **Sent to Groq:** coach messages, and for reports only *aggregates*: app
  names, minutes and times of day. Never a name, email or phone number.
