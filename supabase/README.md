# Supabase setup (OTP sign-in)

Project: `https://ysrusubsulkfemzrlxvx.supabase.co`. The app ships with its URL and publishable key ([lib/main.dart](../lib/main.dart)). Secrets below go only in the Supabase dashboard or `supabase secrets`, never in git.

## 1. Database

Run [migrations/20261121000000_auth_profiles.sql](migrations/20261121000000_auth_profiles.sql) one of two ways:
- with the CLI: `npx supabase login`, then `npx supabase link --project-ref ysrusubsulkfemzrlxvx`, then `npx supabase db push`
- or paste it into **SQL Editor** and run it.

## 2. Email codes (Brevo)

**Quick way:** [config.toml](config.toml) already has the Brevo SMTP settings, 5-minute codes, the 60 s resend cooldown, 30 emails/hour and the code template ([templates/magic_link.html](templates/magic_link.html)).
1. The SMTP key is read from `SMTP_PASS`, which is kept in the gitignored `supabase/.env.local` because GitHub push protection blocks Brevo keys. Export it before pushing: `export SMTP_PASS=…`.
1. `admin_email` in config.toml is the sender (`aziznefeti73@gmail.com`). It must show as verified under Brevo's Senders page.
2. Run `npx supabase login`, then `npx supabase link --project-ref ysrusubsulkfemzrlxvx`, then `npx supabase config push`.

**Manual way (dashboard):**

1. In Brevo, go to **Senders, Domains & Dedicated IPs > Senders** and add and verify the address the emails come from (e.g. your Gmail). The SMTP login `…@smtp-brevo.com` is **not** a sender address.
2. In Supabase, go to **Authentication > Emails > SMTP Settings** and enable custom SMTP:
   - Sender email: the verified Brevo sender. Sender name: `Athar`.
   - Host `smtp-relay.brevo.com`, port `587`.
   - Username: your Brevo SMTP login. Password: your Brevo SMTP key.
3. Under **Authentication > Emails > Templates > Magic Link**, set:
   - Subject: `Your Athar code`
   - Body:
     ```html
     <h2>Your Athar code</h2>
     <p style="font-size:28px;letter-spacing:6px"><b>{{ .Token }}</b></p>
     <p>It expires in 5 minutes. If you didn't ask for it, ignore this email.</p>
     ```
4. **Authentication > Sign In / Providers > Email**: Email enabled, **Email OTP expiration** `300`, OTP length 6.
5. **Authentication > Rate Limits**: emails per hour `30`.

## 3. Telegram codes (bot @AtharccBot), already deployed

Secrets live in `supabase/.env`, committed on purpose for the demo: `TELEGRAM_BOT_TOKEN`, `SEND_SMS_HOOK_SECRET` (`v1,whsec_…`) and `TELEGRAM_WEBHOOK_SECRET`. The Brevo SMTP key is in the gitignored `supabase/.env.local` (as `SMTP_PASS`). After the demo, revoke the bot token in @BotFather (`/revoke`) and delete the SMTP key in Brevo. To redo the setup from scratch:

```sh
npx supabase secrets set --env-file supabase/.env
npx supabase functions deploy send-sms-telegram --no-verify-jwt --use-api
npx supabase functions deploy telegram-webhook --no-verify-jwt --use-api
# config push reads the hook secret from the shell:
export SEND_SMS_HOOK_SECRET=…   # value from supabase/.env
export SMTP_PASS=…              # value from supabase/.env.local
npx supabase config push        # phone sign-in on, 60 s resend wait, Send SMS hook
curl "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/setWebhook" \
  -d url=https://ysrusubsulkfemzrlxvx.supabase.co/functions/v1/telegram-webhook \
  -d secret_token=$TELEGRAM_WEBHOOK_SECRET -d 'allowed_updates=["message"]'
```

Dashboard only: **Authentication > Sign In / Providers > Phone > SMS OTP Expiry** = `300`. `config.toml` has no field for it.

Flow: the app calls `signInWithOtp(phone)`. The Send SMS hook runs `send-sms-telegram`, which looks up `telegram_links`.
- If the number is linked, the bot sends the code.
- If it isn't, the hook fails, and the app shows **Open Telegram**. The user taps Start, then **Share my number**, and `telegram-webhook` stores the link. Then **Send code again**.
