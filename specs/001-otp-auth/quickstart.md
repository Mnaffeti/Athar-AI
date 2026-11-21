# Quickstart: validate OTP sign-in end to end

## Prerequisites

- A Supabase free project, and the Supabase CLI logged in and linked (`supabase link`).
- A Brevo free account with a verified sender and an SMTP key.
- A Telegram bot from @BotFather (token and username).
- Flutter SDK, and a device or emulator with Telegram installed.

## One-time setup

1. Apply the migration (profiles + telegram_links, see [data-model.md](data-model.md)): `supabase db push`.
2. Set the secrets: `supabase secrets set TELEGRAM_BOT_TOKEN=… SEND_SMS_HOOK_SECRET=… TELEGRAM_WEBHOOK_SECRET=…`.
3. Deploy the functions: `supabase functions deploy send-sms-telegram --no-verify-jwt` and `supabase functions deploy telegram-webhook --no-verify-jwt`.
4. Register the webhook: `https://api.telegram.org/bot<TOKEN>/setWebhook?url=https://<ref>.supabase.co/functions/v1/telegram-webhook&secret_token=<TELEGRAM_WEBHOOK_SECRET>`.
5. In the Supabase dashboard:
   - **Auth > SMTP**: Brevo, `smtp-relay.brevo.com`, port 587.
   - **Email template "Magic Link"**: shows `{{ .Token }}` only.
   - **Email OTP expiration**: 300.
   - **Email hourly limit**: 30.
   - **Phone provider**: on, with SMS OTP expiry 300. If a provider is required, enter placeholder values.
   - **Auth Hooks > Send SMS**: HTTP, pointing at the `send-sms-telegram` URL. Copy the generated secret into `SEND_SMS_HOOK_SECRET`, then redeploy or re-set the secret.
6. Run the app: `flutter run --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=… --dart-define=TELEGRAM_BOT_USERNAME=…`.

## Scenarios

| # | Steps | Expected |
|---|---|---|
| 1 | Onboarding, then sign in with email, enter the code | Home screen. A `profiles` row exists with your answers (US1, FR-008) |
| 2 | Enter a wrong code, then the right one | Error message, then success (US1 #3) |
| 3 | Wait over 5 minutes, then enter the code | "Expired" message (US1 #4) |
| 4 | Tap Resend immediately | Countdown blocks it for 60 s (FR-006) |
| 5 | Telegram with a new number | "Not linked" step. Open Telegram, Start, share the number, return, Send code again. Code arrives in Telegram. Sign-in succeeds (US2 #1) |
| 6 | Sign out, then Telegram sign-in with the same number again | Code arrives with no bot step (US2 #2) |
| 7 | In the bot, share a number that differs from the one typed | The bot shows the linked number. The app still says "not linked" (US2 #3) |
| 8 | Kill and relaunch while signed in | Home screen, no code prompt (US3 #1, SC-006) |
| 9 | Profile, then Sign out, then relaunch | Welcome screen (US3 #2) |
| 10 | Email sign-in, then Telegram sign-in on the same device | Two separate accounts in Auth > Users (FR-015) |

## Automated checks

- `flutter test`: phone normalization unit test and `OnboardingAnswers` JSON round-trip.
- `deno test supabase/functions`: phone normalization in the functions, and the contact own-number check.
