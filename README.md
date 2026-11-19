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
