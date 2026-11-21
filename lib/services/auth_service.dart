import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/onboarding_answers.dart';

/// Sign-in with one-time codes (email or Telegram) and the user's profile row.
class AuthService {
  AuthService._();

  static GoTrueClient get _auth => Supabase.instance.client.auth;
  static SupabaseQueryBuilder get _profiles =>
      Supabase.instance.client.from('profiles');

  static bool get isSignedIn => _auth.currentSession != null;

  static Future<void> sendEmailCode(String email) =>
      _auth.signInWithOtp(email: _cleanEmail(email));

  static Future<void> verifyEmail(String email, String code) => _auth.verifyOTP(
    email: _cleanEmail(email),
    token: code,
    type: OtpType.email,
  );

  /// [phone] must already be E.164. Delivered by the Athar Telegram bot.
  static Future<void> sendTelegramCode(String phone) =>
      _auth.signInWithOtp(phone: phone);

  static Future<void> verifyTelegram(String phone, String code) =>
      _auth.verifyOTP(phone: phone, token: code, type: OtpType.sms);

  /// Network and rate-limit failures; anything else on a Telegram send
  /// means the number isn't linked to the bot yet.
  static bool isTransient(Object e) =>
      _isOffline(e) || (e is AuthException && e.statusCode == '429');

  // gotrue also throws AuthRetryableFetchException for any 5xx (e.g. the
  // Telegram hook's "not linked"); only a missing status means no network.
  static bool _isOffline(Object e) =>
      e is AuthRetryableFetchException && e.statusCode == null;

  /// Null when the signed-in account has no profile yet.
  static Future<OnboardingAnswers?> loadProfile() async {
    final row = await _profiles
        .select('answers')
        .eq('id', _auth.currentUser!.id)
        .maybeSingle();
    if (row == null) return null;
    return OnboardingAnswers.fromJson(
      Map<String, dynamic>.from(row['answers'] as Map),
    );
  }

  static Future<void> saveProfile(OnboardingAnswers answers) => _profiles
      .upsert({'id': _auth.currentUser!.id, 'answers': answers.toJson()});

  /// Ends the session on this device only; works offline.
  static Future<void> signOut() => _auth.signOut(scope: SignOutScope.local);

  static String _cleanEmail(String email) => email.trim().toLowerCase();

  /// User-facing text for an auth failure (spec FR-012). Never says whether
  /// an account exists.
  static String errorMessage(Object e, {bool sending = false}) {
    if (_isOffline(e)) {
      return 'No connection. Check your internet and retry.';
    }
    if (e is AuthException) {
      if (e.statusCode == '429' || e.code == 'over_email_send_rate_limit') {
        return 'Too many tries. Wait a minute and retry.';
      }
      // Supabase uses one code for wrong and expired tokens.
      if (e.code == 'otp_expired') {
        return 'That code is wrong or expired. Try again or tap Resend.';
      }
    }
    return sending
        ? "Couldn't send the code right now. Try again or use the other option."
        : 'Something went wrong. Please try again.';
  }
}
