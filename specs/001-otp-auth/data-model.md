# Data Model: OTP Authentication

## auth.users (managed by Supabase)

One row per account: either `email` or `phone` is set, never both (spec FR-015). Supabase creates it on the first verified sign-in. OTPs are stored hashed in Supabase-managed tables (FR-014); we add no OTP table.

## public.profiles

| Column | Type | Rules |
|---|---|---|
| `id` | uuid, PK, FK → `auth.users.id` on delete cascade | equals `auth.uid()` |
| `answers` | jsonb, not null | serialized `OnboardingAnswers` (name, age, heightCm, weightKg, occupation, goal, dailyScreenHours, worstApps[], gymFrequency, phoneFreeGoalHours) |
| `created_at` | timestamptz, default `now()` | |

RLS on, with policies for `select`, `insert` and `update`, each `using/with check (id = auth.uid())`.

## public.telegram_links

| Column | Type | Rules |
|---|---|---|
| `phone` | text, PK | E.164 (`+` and digits), from the shared Telegram contact, normalized |
| `chat_id` | bigint, not null | private chat with the bot |
| `telegram_user_id` | bigint, not null | must equal the contact's `user_id` |
| `linked_at` | timestamptz, default `now()` | updated on re-link |

RLS on, no policies, so the service role only. Upsert on `phone`: if a number moves to another Telegram account, the latest verified owner wins.

## Lifecycle

```text
Signed out ──request code──▶ Code sent ──verify ok──▶ Signed in ──sign out──▶ Signed out
                 │                │
     (Telegram, phone not linked) └─ wrong/expired ─▶ Code sent (retry or resend after 60 s)
                 ▼
        Needs bot link ──user shares contact in bot──▶ (retry request code)
```

Signed in with no `profiles` row → quiz → profile saved → home.

## Phone normalization (shared rule, app and functions)

Strip spaces, dashes, dots and parentheses. Turn a leading `00` into `+`. The result must match `^\+[1-9]\d{6,14}$`. Telegram contacts may omit the `+`; add it before storing.
