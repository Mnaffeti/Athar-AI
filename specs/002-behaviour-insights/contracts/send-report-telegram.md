# Contract: Edge Function `send-report-telegram`

**Caller**: the app, through `supabase.functions.invoke('send-report-telegram', body: …)`.
**Deploy**: `--no-verify-jwt`, like the other functions. The function itself verifies the caller with `auth.getUser(<Bearer token>)` and returns 401 if invalid.

## Request

```json
{ "text": "Report text, ≤ 4000 chars", "chartPngBase64": "iVBORw0K…" }
```

## Behaviour

1. Read the user from the JWT. If `user.phone` is empty, return 403 `not_telegram_account` (FR-013).
2. Normalize the phone and look up `telegram_links.chat_id`. If there's no link, return 404 `telegram_not_linked`.
3. If there's a chart, `sendPhoto(chat_id, png, caption: "Your Athar report")` as multipart.
4. `sendMessage(chat_id, text)`.
5. A Telegram 403 (bot blocked) returns 409 `telegram_blocked`. Any other Telegram error returns 502 `telegram_failed`.

## Responses (`application/json`)

| Case | Status | Body |
|---|---|---|
| Sent | 200 | `{"ok": true}` |
| Not signed in | 401 | `{"error": "unauthorized"}` |
| Email account | 403 | `{"error": "not_telegram_account"}` |
| Not linked | 404 | `{"error": "telegram_not_linked"}` |
| Bot blocked | 409 | `{"error": "telegram_blocked"}` |
| Bad input | 400 | `{"error": "bad_request"}` (no text, text too long, or image over 5 MB) |
