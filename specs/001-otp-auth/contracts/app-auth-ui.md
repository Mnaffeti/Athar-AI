# Contract: App auth screens and AuthService

## AuthService (lib/services/auth_service.dart), static methods

| Method | Wraps | Notes |
|---|---|---|
| `sendEmailCode(email)` | `auth.signInWithOtp(email:)` | lower-cases and trims the email |
| `sendTelegramCode(phone)` | `auth.signInWithOtp(phone:)` | `phone` already normalized to E.164 |
| `verifyEmail(email, code)` / `verifyTelegram(phone, code)` | `auth.verifyOTP(type: email / sms)` | |
| `loadProfile()` → `OnboardingAnswers?` | `profiles` select by `auth.uid()` | null means no profile yet |
| `saveProfile(answers)` | `profiles` upsert | |
| `signOut()` | `auth.signOut()` | |
| `isSignedIn` | `auth.currentSession != null` | |

## Screens

**SignInScreen** (changed): the Apple and Google buttons are removed (FR-016). Two choices:
- Email field with **Send code**, enabled when the format is valid.
- Phone field with **Continue with Telegram**, enabled when the number normalizes (data-model rule).
- Both go to VerifyCodeScreen.

**VerifyCodeScreen** (new):
- Shows the destination, a 6-digit field, **Resend** with a 60 s countdown, and **Change**, which goes back.
- Telegram only: if sending fails, shows "Not linked to the Athar bot yet", **Open Telegram** (`https://t.me/<TELEGRAM_BOT_USERNAME>?start=link`) and **Send code again**.
- Error mapping (FR-012):

| Error | Message |
|---|---|
| Wrong code | "That code isn't right. Try again." |
| Expired | "That code expired. Tap Resend." |
| 429 | "Too many tries. Wait a minute and retry." |
| Network | "No connection. Check your internet and retry." |
| Email send failure (e.g. Brevo cap) | "Couldn't send the email right now. Try Telegram instead." (FR-019) |

- On success:
  - New user who came with answers: save the profile, then go to MainShell.
  - Existing profile: load it, then go to MainShell.
  - No profile and no answers: go to QuizScreen.

**SplashScreen** (changed): if signed in, load the profile and go to MainShell (or to QuizScreen if there's no profile). Otherwise go to WelcomeScreen.

**PlanScreen** (changed): if already signed in, save the profile and go to MainShell instead of pushing SignInScreen.

**ProfileScreen** (changed): a **Sign out** row with a confirm dialog. It calls `signOut` and returns to WelcomeScreen (FR-011).
