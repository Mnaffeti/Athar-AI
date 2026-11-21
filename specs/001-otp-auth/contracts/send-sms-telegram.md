# Contract: Edge Function `send-sms-telegram` (Supabase Send SMS hook)

**Caller**: Supabase Auth, when the app calls `signInWithOtp(phone:)`.
**Deploy**: `--no-verify-jwt`; authenticated by Standard Webhooks signature.

## Request

`POST`, with headers `webhook-id`, `webhook-timestamp`, `webhook-signature`.

```json
{ "user": { "id": "uuid", "phone": "21650123456", "...": "..." }, "sms": { "otp": "561166" } }
```

## Behaviour

1. Verify the signature over the raw body with `SEND_SMS_HOOK_SECRET` (strip `v1,whsec_`). On failure, return 401.
2. Normalize `user.phone` to E.164 and look up `telegram_links.chat_id`.
3. If there's no link, return the error response below.
4. Call Bot API `sendMessage(chat_id, text)` with this text: `Your Athar code is 561166. It expires in 5 minutes. If you didn't ask for it, ignore this message.` (FR-013)
5. If Telegram returns an error, for example because the user blocked the bot, return the error response below.

Never log `sms.otp` or the message text (FR-014).

## Responses (`Content-Type: application/json`)

| Case | Status | Body |
|---|---|---|
| Sent | 200 | `{}` |
| Bad signature | 401 | `{"error":{"http_code":401,"message":"invalid signature"}}` |
| Not linked / delivery failed | 500 | `{"error":{"http_code":500,"message":"telegram_not_linked"}}` |

The app treats any `signInWithOtp(phone:)` failure as "not linked yet" (research R4).
