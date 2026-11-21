# Athar أثر

A Flutter habit app that helps you cut screen time, with an AI coach powered
by [Groq](https://groq.com).

## Running the app

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install).

```
flutter pub get
flutter run --dart-define-from-file=env.json
```

In VS Code, just press F5: the **Athar** launch config in `.vscode/launch.json`
already passes `env.json`.

Without `env.json` (plain `flutter run`) the app still works, but the coach
falls back to canned offline replies.

**In Chrome** (no phone needed; tracking and notifications are off on web):

```
flutter run -d chrome --dart-define-from-file=env.json
```

**Shareable APK** (on Windows, turn on Developer Mode first:
`start ms-settings:developers`):

```
flutter build apk --release --dart-define-from-file=env.json
```

The APK is `build/app/outputs/flutter-apk/app-release.apk`. It works on any
phone, because sign-in runs on the hosted Supabase project.

## Sign-in (email or Telegram code)

Users sign in with a one-time 6-digit code. Sign-up and login are the same
flow: a new email or phone number creates an account, a known one logs in.

- **Email:** enter your email address. The code comes by email, sent through
  Brevo.
- **Telegram:** enter your Telegram phone number with the country code.
  - The first time, tap **Open Telegram**. In
    [@AtharccBot](https://t.me/AtharccBot), tap **Start**, then **Share my
    number**. Come back to the app and tap **Send code again**.
  - After that, the code arrives straight away.
- You stay signed in until **Profile > Sign out**.

Each email and each phone number is a separate account. Your onboarding
answers are saved to your account.

Backend: [Supabase](https://supabase.com) free tier. Auth handles codes and
sessions; Postgres has the `profiles` and `telegram_links` tables. Two Edge
Functions deliver the Telegram codes and receive the bot's messages. Setup,
deployment and troubleshooting are in [supabase/README.md](supabase/README.md).
The feature spec and plan are in [specs/001-otp-auth/](specs/001-otp-auth/).

> **Demo secrets.** This is an academic demo, so all keys are committed on
> purpose:
> - the Supabase URL and publishable key, in `lib/main.dart`
> - the Brevo SMTP key is the exception: GitHub blocks it, so it lives in
>   the gitignored `supabase/.env.local` (Supabase already has it)
> - the bot token and hook secrets, in `supabase/.env`
>
> After the demo, revoke the bot token in @BotFather (`/revoke`) and delete
> the SMTP key in Brevo.

## Screen-time report (Stats tab)

On Android, the Stats tab shows your real screen time from the last 7 days: a
daily chart and your top 5 apps. Grant **usage access** when asked. On web and
iPhone, the charts show labelled sample data.

With 3 or more days of data, tap **Generate my report** for:

- patterns in how you use your phone
- a forecast for next week, with ranges
- your riskiest times of day
- 3 suggestions tied to your goal

Every number is computed on the phone. Groq only writes the wording, and gets
only app names, minutes and times of day, never your name, email or phone. If
Groq is unavailable, you get an offline summary instead. You can generate a new
report once an hour.

Accounts that signed in with Telegram can tap **Send to Telegram** to get the
chart and the text from @AtharccBot. The `send-report-telegram` function
handles this; see [specs/002-behaviour-insights/](specs/002-behaviour-insights/).

## Groq API key (AI coach)

1. Create a free key at <https://console.groq.com/keys>.
2. Copy the example file and paste your key:

   ```
   cp env.example.json env.json
   ```

   ```json
   {
     "GROQ_API_KEY": "gsk_..."
   }
   ```

3. Run with `--dart-define-from-file=env.json` (see above). The key is baked in
   at build time, so restart the app (not hot reload) after changing it.

`env.json` is gitignored. Never commit your key.

Optional: add `"GROQ_MODEL"` to `env.json` to override the default model
(`openai/gpt-oss-120b`).

## Daily device tracking API

The **Track** tab collects screen time, scroll time, social-media time, gym time
and phone-free time. Configure a tracking API with optional values in
`env.json`:

```json
{
  "TRACKING_API_URL": "https://your-api.example.com/tracking",
  "TRACKING_API_KEY": ""
}
```

The app sends `POST` requests to this URL with:

```json
{
  "date": "2026-11-19",
  "screen_hours": 3.4,
  "scroll_minutes": 312,
  "social_hours": 1.2,
  "gym_hours": 1.25,
  "phone_free_hours": 2.6
}
```

It loads today's entry with `GET <TRACKING_API_URL>?date=YYYY-MM-DD`. The API
may return the entry directly or inside `data`/`tracking`. If no tracking API
is configured, the app keeps the demo values and saves locally for the current
session.

> Note: keys passed this way are embedded in the built app. Fine for local
> development; for a public release, proxy requests through a backend instead.

## Screenshots

Render every screen (splash, quiz, plan, sign-up, home, stats, coach, profile)
on a small and a large phone:

```
flutter test --update-goldens test_screenshots
```

PNGs are written to `screenshots/small_phone/` and `screenshots/large_phone/`.
Long screens also get a `_full` image showing the whole page.
