# Research: OTP Authentication (Telegram & Email)

Facts checked against Supabase and Telegram docs on 2026-11-21. Scope: academic demo, free tiers only.

## R1. Backend

- **Decision**: Supabase free plan: Auth, Postgres and Edge Functions.
- **Rationale**: Auth already does OTP generation, hashing, expiry, resend cooldown, verify rate limits and refresh-token sessions, so we write no security code ourselves. Free plan: 50k MAU, 500 MB DB, 500k function invocations/month, far above demo needs.
- **Caveat**: free projects pause after 7 days of inactivity. Unpause from the dashboard before a demo.
- **Alternatives**: Cloudflare Workers + D1 (would need hand-written OTP/session logic); Firebase (Functions need the paid Blaze plan); self-hosted PocketBase (ops overhead).

## R2. Email codes

- **Decision**: `signInWithOtp(email:)` + `verifyOTP(type: OtpType.email)`. Brevo as custom SMTP (`smtp-relay.brevo.com:587`, SMTP key). Magic Link template replaced with one showing only `{{ .Token }}`. Email OTP expiration = 300 s.
- **Rationale**: Custom SMTP is included on Free, and lifts Supabase's built-in 2 emails/hour limit. No function code needed.
- **Alternatives**: Send Email hook calling Brevo's HTTP API (more code, no demo benefit).
- **To verify during setup**: Brevo free daily cap (expected ~300/day) and sender verification on Brevo's dashboard.

## R3. Telegram codes

- **Decision**: Phone auth with the **Send SMS hook** (available on Free) pointed at Edge Function `send-sms-telegram`, which sends `sms.otp` to the chat linked to `user.phone` through the Telegram Bot API. A second Edge Function `telegram-webhook` receives bot updates and stores phone → chat links.
- **Rationale**: Bot API is free. Supabase still owns code generation, expiry and verification; our function is only a delivery pipe.
- **Alternatives**: Telegram Gateway API (sends to any number without setup, but paid per message).

## R4. First-time Telegram linking

- **Decision**: The bot can only message users who started it. On `/start`, the bot replies with a one-button keyboard (`request_contact: true`). On a `contact` message, it accepts it only if `contact.user_id == from.id` (the sender shared their own number), then upserts `telegram_links(phone, chat_id)` and replies "Linked +XXX. Go back to Athar."
- **App side**: any failure from `signInWithOtp(phone:)` is shown as "This number isn't linked to the Athar bot yet", with an **Open Telegram** button (`https://t.me/<bot>?start=link`, via `url_launcher`) and **Send code again**.
- **Why generic failure handling**: the docs don't confirm that an HTTP hook's error message reaches the client, so the app doesn't depend on it.
- **Mismatch case**: if the user shares a different number than the one typed, the link is stored for the shared number, the typed number still fails, and the bot reply shows which number was linked.

## R5. Hook and webhook security

- **Send SMS hook**: verify the Standard Webhooks signature (`webhook-id`, `webhook-timestamp`, `webhook-signature`) with the secret after stripping `v1,whsec_`. Deploy with `--no-verify-jwt`. Return `{}` with 200 on success, or `{"error":{"http_code":500,"message":"..."}}` with `Content-Type: application/json`. Never log `sms.otp`.
- **Telegram webhook**: register with `setWebhook(secret_token=…)` and reject requests without a matching `X-Telegram-Bot-Api-Secret-Token` header. Deploy with `--no-verify-jwt`.
- **`telegram_links`**: RLS on, no policies. Only the service role, inside functions, can read or write it.

## R6. Sessions

- **Decision**: rely on `supabase_flutter`'s built-in session persistence and auto-refresh. Refresh tokens never expire on Free, and time-boxed or inactivity sessions are Pro-only, so the spec's 30-day expiry was dropped (FR-010).
- **Sign-out**: `auth.signOut()`, then back to `WelcomeScreen`.

## R7. Rate limits (built-in, demo-adequate)

- 60 s between OTP sends per user (email and SMS).
- 30 verify requests per 5 min per IP.
- 30 SMS/hour project-wide (default). The email hourly cap is configurable with custom SMTP; set 30.
- Spec FR-006 was amended to match these.

## R8. Profile storage (FR-008)

- **Decision**: table `profiles(id = auth.users.id, answers jsonb)`. Add `toJson`/`fromJson` to `OnboardingAnswers`.
  - New user from onboarding: insert after the code is verified.
  - Returning user with a profile: load it.
  - Signed in with no profile (a new destination from Welcome): send them to the quiz. The plan screen then saves the profile instead of pushing sign-in.
- **Rationale**: one JSON column matches the in-memory model with no column-by-column mapping.

## R9. App architecture

- **Decision**: keep the current `setState` + `lib/services/` pattern. Add one `AuthService` beside `tracking_service.dart` with static methods over `Supabase.instance.client`.
- **Note**: the project memory says MVVM is planned for when real data lands. Auth is the first real data, but moving the whole app to MVVM is a separate change, so it isn't part of this feature.

## R10. Config and secrets

- **App**: `SUPABASE_URL`, `SUPABASE_ANON_KEY` and `TELEGRAM_BOT_USERNAME` via `--dart-define`. The anon key is public by design.
- **Functions**: `TELEGRAM_BOT_TOKEN`, `SEND_SMS_HOOK_SECRET` and `TELEGRAM_WEBHOOK_SECRET` via `supabase secrets set`. Never committed.

## Open items verified only by test (see quickstart)

- Whether the phone provider can be enabled with only the Send SMS hook. If the dashboard insists on a provider, enter placeholder Twilio values; the hook bypasses them.
- That `request_contact` shares the sender's own number. Expected Telegram behaviour, and the `user_id == from.id` check guards it anyway.
