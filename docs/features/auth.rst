Feature 001: OTP sign-in (email or Telegram)
=============================================

**Spec folder:** ``specs/001-otp-auth/`` · **Status:** merged (PR #2)

What it does
------------

* **Email:** enter an email, receive a 6-digit code (sent through Brevo),
  type it in.
* **Telegram:** enter the phone number on your Telegram account.

  - The first time, the app shows **Open Telegram**. In @AtharccBot, tap
    **Start**, then **Share my number**, then **Send code again**.
  - After that, the code arrives straight away.

* **One flow for sign-up and login:** a new email or number creates an
  account, and a known one logs into it. Each email and each number is its
  own account.
* **Sessions** survive restarts. **Profile > Sign out** ends them.
* **Onboarding answers** are saved to the account's ``profiles`` row.

How a Telegram code travels
---------------------------

.. code-block:: text

   App: signInWithOtp(phone)
     → Supabase Auth creates the code
     → Send SMS hook → send-sms-telegram (checks the Standard Webhooks signature)
     → telegram_links lookup → Bot API sendMessage → user's Telegram
   Not linked yet → the hook fails → the app shows "Open Telegram"
     → the user shares their contact → telegram-webhook checks it's their own number
     → telegram_links upsert → the user taps "Send code again"

Main files
----------

.. list-table::
   :header-rows: 1
   :widths: 45 55

   * - File
     - Role
   * - ``lib/services/auth_service.dart``
     - Send and check codes, load and save the profile, sign out, and turn
       errors into user-facing messages
   * - ``lib/screens/auth/sign_in_screen.dart``
     - Email and Telegram inputs, plus the bot-link panel
   * - ``lib/screens/auth/verify_code_screen.dart``
     - 6-digit entry, 60-second resend, and routing after a successful code
   * - ``supabase/migrations/20261121000000_auth_profiles.sql``
     - The ``profiles`` and ``telegram_links`` tables, with row-level security
   * - ``supabase/functions/send-sms-telegram/index.ts``
     - The Auth hook that delivers codes through the bot
   * - ``supabase/functions/telegram-webhook/index.ts``
     - Links a user's own phone number to their chat
   * - ``supabase/config.toml``, ``templates/magic_link.html``
     - SMTP, code expiry, rate limits and the email template

Notable fix
-----------

The Supabase client throws its "retryable fetch" error for **any** response
of 500 or above (``gotrue`` ``fetch.dart:49``), not only for network
failures. The app therefore showed "No connection" when the real cause was
"number not linked". ``AuthService`` now treats only errors *without* a
status code as offline, and ``test/auth_errors_test.dart`` guards against a
regression.
