# Feature Specification: OTP Authentication (Telegram & Email)

**Feature Branch**: `001-otp-auth`

**Created**: 2026-11-21

**Status**: Draft

**Input**: User description: "i want to add auth module management, with otp code being sent to telegram number, or mail, sign in and login now can use telegram otp code or mail code"

## Clarifications

### Session 2026-11-21

- Q: Can one account be reached through both email and Telegram? → A: No. Each email and each phone number is its own account.
- Q: What happens to the Apple and Google buttons? → A: Remove them; only email and Telegram remain.
- Q: Real or mocked code delivery? → A: Real delivery, through a server-side service.
- Q: Budget? → A: Free tiers only. Email through a free provider such as Brevo; Telegram through Athar's own bot.
- Q: Scale? → A: Academic demo project. Limits that free tiers do not offer (per-code attempt counter, per-destination hourly cap, 30-day inactivity expiry) are dropped in favour of the built-in equivalents.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sign in with an email code (Priority: P1)

A person on the sign-in screen enters their email address, receives a one-time code by email, types it into the app, and lands in the app signed in. If no account exists for that email, one is created and linked to the plan they just built in onboarding; if one exists, they return to their existing profile and streak.

**Why this priority**: Email is the channel every user has. On its own it replaces today's mocked "Continue with email" button with real, verified sign-in, which is the minimum viable auth module.

**Independent Test**: Enter a reachable email address, receive the code, enter it, and confirm the app opens on the home screen with the correct profile. Repeat with the same email from a fresh install and confirm the same account is restored.

**Acceptance Scenarios**:

1. **Given** a new user who finished onboarding, **When** they enter a valid email and the correct code, **Then** an account is created with their onboarding plan and they reach the home screen.
2. **Given** a returning user, **When** they enter their registered email and the correct code, **Then** they reach the home screen with their existing profile.
3. **Given** a user who requested a code, **When** they enter a wrong code, **Then** they see an "incorrect code" message and can try again without requesting a new code.
4. **Given** a user who requested a code, **When** they enter it after it expired, **Then** they are told the code expired and offered a new one.

---

### User Story 2 - Sign in with a Telegram code (Priority: P2)

A person chooses "Continue with Telegram" and enters the phone number linked to their Telegram account. The first time, the app opens Athar's Telegram bot; the user taps Start and shares their phone number with one tap. The bot then sends a one-time code, the user enters it in the app, and is signed in. On later sign-ins with the same number, the bot sends the code directly, without the user opening it first. Account creation and return work the same as for email.

**Why this priority**: This is the second channel the user asked for, and it suits people who prefer messaging over email. It depends on the same code-verification flow as Story 1, so it comes after it.

**Independent Test**: Enter a phone number that has a Telegram account, open the bot, share the number, receive the code in Telegram, enter it, and confirm sign-in succeeds. Sign in again on a second device and confirm the code arrives without opening the bot first.

**Acceptance Scenarios**:

1. **Given** a first-time Telegram user, **When** they enter their phone number, open the bot, share their number, and enter the correct code, **Then** they are signed in.
2. **Given** a user whose number is already known to the bot, **When** they request a code, **Then** the bot sends it directly and they can sign in without opening the bot first.
3. **Given** a user who shares a Telegram number that differs from the one entered in the app, **When** they request a code, **Then** no code is sent; the bot shows which number it linked, and the app tells the user the entered number is not linked yet.
4. **Given** a malformed phone number, **When** the user tries to request a code, **Then** the request is blocked with a message explaining the expected format.

---

### User Story 3 - Stay signed in and sign out (Priority: P3)

Once signed in, the user stays signed in across app restarts until they sign out from their profile. Signing out returns them to the welcome screen and requires a new code to get back in.

**Why this priority**: Without it, users would need a code at every launch. It is useful only after Story 1 or 2 exists.

**Independent Test**: Sign in, kill and relaunch the app, and confirm the home screen opens directly. Sign out from the profile and confirm relaunch shows the welcome screen.

**Acceptance Scenarios**:

1. **Given** a signed-in user, **When** they relaunch the app, **Then** they land on the home screen without entering a code.
2. **Given** a signed-in user, **When** they tap "Sign out" in their profile and confirm, **Then** they return to the welcome screen and their session ends.

---

### Edge Cases

- The user requests several codes in a row: only the most recent code is valid, and a resend is allowed only after a 60-second cooldown.
- The user enters a wrong code repeatedly: after 30 checks in 5 minutes from one network address, further checks are refused until the window passes.
- Many code requests target one email or phone number: the 60-second cooldown and the app-wide hourly cap limit spam.
- The device is offline when requesting or verifying a code: the user sees a "no connection" message and nothing is lost when they retry.
- The email lands in spam or never arrives: the code screen tells the user to check spam and offers resend or switching to the other channel.
- The user does not have Telegram installed: tapping "Open Telegram" opens the bot in a web browser or app store, and the screen offers email instead.
- The user blocks the bot after sharing their number: the code cannot be delivered, and the user is asked to open the bot again.
- The user opens the bot but never shares their number: no code is sent, and the app screen keeps waiting with a hint to share the number in Telegram.
- The user leaves the app to copy the code and comes back: the code screen is still there with the destination shown.
- Email addresses differ only in letter case: they are treated as the same account.
- Phone numbers are entered with spaces, dashes or a leading "00": they are normalized to one international format before use.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to request a one-time sign-in code by entering an email address.
- **FR-002**: Users MUST be able to request a one-time sign-in code by entering a phone number linked to a Telegram account, with the code delivered as a Telegram message from Athar's bot.
- **FR-002a**: The first time a phone number is used, the app MUST open Athar's Telegram bot, and the bot MUST ask the user to share their own Telegram phone number. A code is sent only to a number that its own Telegram owner has shared with the bot, so a code for the number entered in the app reaches that number's owner only.
- **FR-002b**: Once a phone number has been shared with the bot, later code requests for that number MUST be delivered directly, without the user opening the bot first.
- **FR-003**: The system MUST validate the email or phone format before sending a code and show a clear message when it is invalid.
- **FR-004**: Codes MUST be 6 digits, single-use, and expire 5 minutes after they are sent.
- **FR-005**: Requesting a new code MUST invalidate any earlier unused code for the same destination.
- **FR-006**: The system MUST enforce a 60-second resend cooldown per destination, limit code-check attempts (30 per 5 minutes per network address), and cap total codes sent per hour across the app, and tell the user when they hit a limit and when they can retry.
- **FR-007**: A single flow MUST cover both sign-up and login: a verified destination with no account creates one, and a verified destination with an account signs into it.
- **FR-008**: A newly created account MUST keep the onboarding answers the user gave before signing in.
- **FR-009**: The code entry screen MUST show where the code was sent, offer resend after the cooldown, and let the user change the destination or switch channel.
- **FR-010**: Users MUST stay signed in across app restarts until they sign out.
- **FR-011**: Users MUST be able to sign out from their profile, which ends the session on that device.
- **FR-012**: Messages for failures (wrong code, expired code, delivery failure, limit reached, no connection) MUST tell the user what happened and what to do next, without revealing whether an account exists for a given destination.
- **FR-013**: The code message (email and Telegram) MUST state the app name, that the code expires in 5 minutes, and that the user should ignore it if they did not request it.
- **FR-014**: The system MUST NOT store codes in readable form and MUST NOT write codes to logs.
- **FR-015**: Each account MUST be tied to exactly one sign-in destination: one email address or one Telegram phone number. Signing in with a different destination creates or opens a different account; linking channels is not supported.
- **FR-016**: The sign-in screen MUST offer only email and Telegram; the "Continue with Apple" and "Continue with Google" options MUST be removed.
- **FR-017**: Codes MUST be delivered for real: to the user's actual email inbox and actual Telegram account, and verified by a server-side service, not by the app alone.
- **FR-018**: Every part of this feature (email sending, Telegram delivery, the server-side service, and account storage) MUST run on free tiers with no per-message or monthly cost at launch scale.
- **FR-019**: When the email provider's daily free sending limit is reached, users MUST see a message offering Telegram instead, and the limit MUST NOT block Telegram sign-in.

### Key Entities

- **User Account**: one person using Athar. Holds an account identifier, exactly one verified destination (an email or a Telegram phone number) and its channel, the onboarding answers, and the creation date.
- **Sign-in Code**: a pending one-time code. Holds the destination, channel (email or Telegram), send time, expiry, wrong-attempt count, and whether it was used.
- **Session**: proof that a device is signed in to an account. Holds the account, device, start time, and last-used time.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can go from the sign-in screen to the home screen in under 60 seconds with email, or with Telegram after the first bot setup (first Telegram sign-in: under 90 seconds).
- **SC-007**: Running cost of the feature is zero per month at launch scale.
- **SC-002**: 95% of codes arrive within 30 seconds of being requested.
- **SC-003**: At least 90% of users who request a code complete sign-in on their first code.
- **SC-004**: A returning user on a new device sees their existing profile and streak after signing in, in 100% of test runs.
- **SC-005**: No code can be used twice, used after expiry, or guessed within the attempt limit, verified by test cases for each.
- **SC-006**: Signed-in users relaunching the app reach the home screen without a code prompt in 100% of test runs.

## Assumptions

- "Telegram number" means the phone number linked to the user's Telegram account; usernames are out of scope.
- A user who switches channel (email to Telegram or back) reaches a different account. Users are expected to keep using the channel they signed up with.
- The app has no server today. This feature depends on a new server-side service that sends emails, sends Telegram messages, verifies codes, and stores accounts and sessions; that service is in scope.
- Telegram codes are sent by Athar's own Telegram bot, which is free. Telegram's paid service for sending codes straight to any phone number is not used, which is why the first sign-in needs the user to open the bot once.
- Email is sent through a provider with a free tier; the user prefers Brevo, whose free plan has a daily sending cap (about 300 emails per day). That cap is enough at launch scale.
- The server-side service and account storage run on a free hosting tier; if usage outgrows free limits, moving to a paid tier is a later decision.
- Passwords are out of scope; codes are the only sign-in credential for email and Telegram.
- The sign-in step stays where it is today: after onboarding for new users, and from the welcome screen for returning users.
- Account deletion, changing a verified email or phone number, and multi-device session management are out of scope for this release.
- Code expiry (5 minutes) and the 60-second cooldown follow common practice for mobile OTP sign-in; this is a demo, so no session time limit applies.
- Code messages are in the same language as the app UI (English today).
