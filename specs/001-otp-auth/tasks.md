# Tasks: OTP Authentication (Telegram & Email)

**Input**: Design documents from `/specs/001-otp-auth/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Only the small unit tests listed in plan.md and quickstart.md (phone normalization, JSON round-trip, contact check). End-to-end checks are manual, per quickstart.md.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: US1 = email code, US2 = Telegram code, US3 = stay signed in / sign out

---

## Phase 1: Setup

- [X] T001 Add `supabase_flutter` and `url_launcher` to `dependencies` in pubspec.yaml and run `flutter pub get`
- [X] T002 [P] Run `supabase init` at the repo root to create supabase/config.toml, and add `supabase/.temp/` and `supabase/.env*` to .gitignore
- [X] T003 [P] Add the Android `<queries>` intent for `https` VIEW (needed by url_launcher) in android/app/src/main/AndroidManifest.xml, and `LSApplicationQueriesSchemes` with `https` and `tg` in ios/Runner/Info.plist

---

## Phase 2: Foundational (blocks all stories)

- [X] T004 Write the migration supabase/migrations/20261121000000_auth_profiles.sql. It creates `public.profiles(id uuid pk references auth.users on delete cascade, answers jsonb not null, created_at timestamptz default now())` with RLS and select/insert/update policies `id = auth.uid()`, and `public.telegram_links(phone text pk, chat_id bigint not null, telegram_user_id bigint not null, linked_at timestamptz default now())` with RLS on and no policies (see data-model.md)
- [X] T005 Initialize Supabase in lib/main.dart: `await Supabase.initialize(url: const String.fromEnvironment('SUPABASE_URL'), anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'))` before `runApp`, and assert both are non-empty with a clear message
- [X] T006 [P] Add `Map<String, dynamic> toJson()` and `factory OnboardingAnswers.fromJson(Map<String, dynamic>)` covering every field (worstApps as a list) in lib/models/onboarding_answers.dart
- [X] T007 [P] Unit test for the JSON round-trip of a filled `OnboardingAnswers` in test/onboarding_answers_test.dart
- [X] T008 Create lib/services/auth_service.dart as a static class over `Supabase.instance.client`, with `isSignedIn`, `loadProfile()` → `OnboardingAnswers?`, `saveProfile(answers)` (upsert into `profiles` with `id = auth.currentUser!.id`) and `signOut()` (see contracts/app-auth-ui.md)
- [X] T009 Create lib/screens/auth/verify_code_screen.dart. It takes a destination label, a `Future<void> Function() resend` and a `Future<void> Function(String code) verify`, plus optional `answers`. It shows the destination, a 6-digit field, **Resend** with a 60 s countdown, and **Change**, which pops. It maps `AuthException` and network errors to the messages in contracts/app-auth-ui.md. After a successful verify it routes: answers present → `saveProfile` → MainShell; profile exists → MainShell(profile); neither → QuizScreen. Match the styling of sign_in_screen.dart

**Checkpoint**: the app starts against a Supabase project, and the shared code screen exists.

---

## Phase 3: User Story 1 - Sign in with an email code (P1) 🎯 MVP

**Goal**: real sign-in with an email code, for new and returning users.

**Independent test**: quickstart scenarios 1–4.

- [X] T010 [US1] Add `sendEmailCode(email)` (`signInWithOtp(email: email.trim().toLowerCase())`) and `verifyEmail(email, code)` (`verifyOTP(type: OtpType.email)`) to lib/services/auth_service.dart
- [X] T011 [US1] Rewrite lib/screens/auth/sign_in_screen.dart: remove `_SocialButton` and the Apple/Google buttons (FR-016). Make **Continue with email** call `sendEmailCode` and push `VerifyCodeScreen` with `resend`/`verify` bound to the email and `widget.answers`. Show the email send-failure message offering Telegram (FR-019). Remove the 800 ms fake delay
- [X] T012 [US1] In lib/screens/onboarding/plan_screen.dart, if `AuthService.isSignedIn`, call `saveProfile(a)` and `pushAndRemoveUntil(MainShell(profile: a))` instead of pushing SignInScreen (for users who signed in with no profile)
- [X] T013 [P] [US1] Write the dashboard setup steps for email (Brevo SMTP, Magic Link template with `{{ .Token }}` and the FR-013 wording, OTP expiry 300 s, email hourly limit 30) in supabase/README.md

**Checkpoint**: email sign-in works end to end; the MVP can be demoed.

---

## Phase 4: User Story 2 - Sign in with a Telegram code (P2)

**Goal**: codes delivered by the Athar Telegram bot, with a one-time bot link step.

**Independent test**: quickstart scenarios 5–7 and 10.

- [X] T014 [P] [US2] Create lib/utils/phone.dart with `String? normalizeE164(String input)`: strip spaces, dashes, dots and parentheses, turn a leading `00` into `+`, and return null unless it matches `^\+[1-9]\d{6,14}$`
- [X] T015 [P] [US2] Unit tests in test/phone_test.dart: `+216 50-123-456` → `+21650123456`, `0021650123456` → `+21650123456`, and `12345`, `abc` and an empty string → null
- [X] T016 [P] [US2] Create supabase/functions/_shared/phone.ts with `normalizeE164` (same rule; also accept a missing `+` from Telegram contacts) and `isOwnContact(message)` (`message.contact.user_id === message.from.id`), plus supabase/functions/_shared/phone_test.ts with Deno tests for both
- [X] T017 [US2] Implement supabase/functions/send-sms-telegram/index.ts per contracts/send-sms-telegram.md:
  - Verify the Standard Webhooks signature with `SEND_SMS_HOOK_SECRET` (strip `v1,whsec_`; `npm:standardwebhooks`).
  - Look up `telegram_links.chat_id` for the normalized `user.phone` with a service-role client.
  - Call Bot API `sendMessage` with the FR-013 text.
  - Return `{}`, or the JSON error, with `Content-Type: application/json`.
  - Never log the OTP.
- [X] T018 [US2] Implement supabase/functions/telegram-webhook/index.ts per contracts/telegram-webhook.md:
  - Reject a missing or wrong `X-Telegram-Bot-Api-Secret-Token`.
  - On `/start` or any other text, reply with the `request_contact` keyboard.
  - On an own contact, upsert into `telegram_links` and reply "Linked +XXX…", removing the keyboard.
  - On a foreign contact, reply "share your own number".
  - Always return 200 after a valid secret.
- [X] T019 [US2] Add `sendTelegramCode(phone)` (`signInWithOtp(phone:)`) and `verifyTelegram(phone, code)` (`verifyOTP(type: OtpType.sms)`) to lib/services/auth_service.dart
- [X] T020 [US2] In lib/screens/auth/sign_in_screen.dart, add a phone field with **Continue with Telegram**, enabled when `normalizeE164` is non-null. It calls `sendTelegramCode`. On any failure it shows the "Not linked to the Athar bot yet" panel with **Open Telegram** (`launchUrl('https://t.me/${const String.fromEnvironment('TELEGRAM_BOT_USERNAME')}?start=link')`, external app) and **Send code again**. On success it pushes `VerifyCodeScreen` bound to the phone
- [X] T021 [P] [US2] Add the Telegram setup steps to supabase/README.md: BotFather, `supabase secrets set`, deploying both functions with `--no-verify-jwt`, `setWebhook` with `secret_token`, enabling the phone provider (placeholder provider values if required), the Send SMS hook URL and secret, and SMS OTP expiry 300 s

**Checkpoint**: Telegram sign-in works, including first-time linking.

---

## Phase 5: User Story 3 - Stay signed in and sign out (P3)

**Goal**: the session survives restarts; sign-out ends it.

**Independent test**: quickstart scenarios 8–9.

- [X] T022 [US3] In lib/screens/splash_screen.dart `_goNext`: if `AuthService.isSignedIn`, `await loadProfile()` and replace with MainShell(profile), or QuizScreen when null. Otherwise go to WelcomeScreen as today. Guard with `mounted` after the await
- [X] T023 [US3] In lib/screens/profile/profile_screen.dart, make the existing **Sign out** button show a confirm dialog, `await AuthService.signOut()`, then `pushAndRemoveUntil(WelcomeScreen)`

**Checkpoint**: all three stories work.

---

## Phase 6: Polish

- [ ] T024 [P] Remove `OnboardingAnswers.demo()` if nothing references it after T011 and T022 (grep first), in lib/models/onboarding_answers.dart
- [ ] T025 [P] Remove the `isReturningUser` flag from SignInScreen if it's still only cosmetic (keep the "Welcome back" title if you want it), in lib/screens/auth/sign_in_screen.dart and lib/screens/onboarding/welcome_screen.dart
- [ ] T026 Run `flutter analyze`, `flutter test` and `deno test supabase/functions`, fix the findings, then walk through quickstart.md scenarios 1–10

---

## Dependencies & Execution Order

- **Setup (T001–T003)** → **Foundational (T004–T009)** → the user stories.
- **US1 (T010–T013)**: needs only Foundational. This is the MVP.
- **US2 (T014–T021)**: needs Foundational. It shares sign_in_screen.dart with US1, so do T020 after T011.
- **US3 (T022–T023)**: needs Foundational (`loadProfile`, `signOut`). It can be tested with either US1 or US2.
- **Polish (T024–T026)**: after the stories you want to ship.
- Within US2: T014 → T020; T016 → T017 and T018; T019 → T020.

## Parallel Examples

- Setup: T002 and T003 together, after T001.
- Foundational: T006, T007 and T004 together; then T008 → T009.
- US2: T014, T015, T016 and T021 together; then T017 and T018 in parallel (different functions); then T019 → T020.

## Implementation Strategy

1. **MVP**: Setup, then Foundational, then US1, then validate quickstart 1–4. Email sign-in is demo-ready.
2. **Add US2**: Telegram, validated with quickstart 5–7 and 10.
3. **Add US3**: persistent session and sign-out, validated with quickstart 8–9.
4. **Polish**: T024–T026.

The code can be written before any accounts exist. Running it needs a Supabase project, a Brevo SMTP key and a Telegram bot token (supabase/README.md).
