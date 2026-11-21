# Contract: Edge Function `telegram-webhook` (Telegram bot updates)

**Caller**: Telegram, registered with `setWebhook(url, secret_token=TELEGRAM_WEBHOOK_SECRET)`.
**Deploy**: `--no-verify-jwt`; authenticated by header `X-Telegram-Bot-Api-Secret-Token`.

## Behaviour

| Incoming update | Action | Bot reply |
|---|---|---|
| Header missing or wrong | Return 401 and do nothing | none |
| `message.text` starts with `/start` | | "Share your phone number to get Athar sign-in codes here." Keyboard: one button `{text: "Share my number", request_contact: true}`, one-time |
| `message.contact` where `contact.user_id == from.id` | Normalize the phone and upsert `telegram_links(phone, chat_id = chat.id, telegram_user_id = from.id)` | "Linked +XXX. Go back to Athar and tap Send code." Remove the keyboard |
| `message.contact` from someone else's contact | Don't store anything | "Please share your own number with the button." |
| Anything else | | Same as `/start` |

Always return 200 to Telegram after a valid secret, so it doesn't retry. The bot message is sent through the webhook reply or `sendMessage`.
