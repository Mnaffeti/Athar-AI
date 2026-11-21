import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/onboarding_answers.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone.dart';
import 'verify_code_screen.dart';

const _botLink = 'https://t.me/AtharccBot?start=link';

/// Sign-up and login in one flow: a one-time code by email or Telegram.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.answers, this.isReturningUser = false});

  /// Quiz answers for new users; saved to the account after the code is verified.
  final OnboardingAnswers? answers;
  final bool isReturningUser;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _error;

  /// Set when a Telegram send failed because the number isn't linked yet.
  bool _telegramNotLinked = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _emailValid => _emailPattern.hasMatch(_emailController.text.trim());
  String? get _phone => normalizeE164(_phoneController.text);

  Future<void> _sendCode({
    required String destination,
    required Future<void> Function() send,
    required Future<void> Function(String code) verify,
    bool telegram = false,
  }) async {
    setState(() {
      _loading = true;
      _error = null;
      _telegramNotLinked = false;
    });
    try {
      await send();
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(
            destination: destination,
            resend: send,
            verify: verify,
            answers: widget.answers,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (telegram && !AuthService.isTransient(e)) {
          _telegramNotLinked = true;
        } else {
          _error = AuthService.errorMessage(e, sending: true);
        }
      });
    }
  }

  void _sendEmailCode() {
    final email = _emailController.text.trim();
    _sendCode(
      destination: email,
      send: () => AuthService.sendEmailCode(email),
      verify: (code) => AuthService.verifyEmail(email, code),
    );
  }

  void _sendTelegramCode() {
    final phone = _phone!;
    _sendCode(
      destination: '$phone on Telegram',
      send: () => AuthService.sendTelegramCode(phone),
      verify: (code) => AuthService.verifyTelegram(phone, code),
      telegram: true,
    );
  }

  Future<void> _openBot() async {
    final opened = await launchUrl(
      Uri.parse(_botLink),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      setState(() => _error = "Couldn't open Telegram. Use email instead.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isReturningUser
        ? 'Welcome back'
        : 'Create your account';
    final subtitle = widget.isReturningUser
        ? 'Sign in to pick up your streak.'
        : 'Save your plan and sync your progress across devices.';

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                hintText: 'you@email.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) =>
                  _emailValid && !_loading ? _sendEmailCode() : null,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading || !_emailValid ? null : _sendEmailCode,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.onAccent,
                      ),
                    )
                  : const Text('Send code by email'),
            ),
            const SizedBox(height: 28),
            const Row(
              children: [
                Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(
                hintText: '+216 50 123 456',
                prefixIcon: Icon(Icons.send_rounded),
                helperText: 'Your Telegram phone number, with country code',
              ),
              onChanged: (_) => setState(() => _telegramNotLinked = false),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loading || _phone == null ? null : _sendTelegramCode,
              child: const Text('Send code on Telegram'),
            ),
            if (_telegramNotLinked) ...[
              const SizedBox(height: 16),
              _BotLinkPanel(
                onOpenBot: _openBot,
                onRetry: _loading ? null : _sendTelegramCode,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.alert, fontSize: 14),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'By continuing you agree to our Terms and Privacy Policy.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// First-time Telegram step: open the bot, share the number, come back.
class _BotLinkPanel extends StatelessWidget {
  const _BotLinkPanel({required this.onOpenBot, required this.onRetry});

  final VoidCallback onOpenBot;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'This number isn\'t linked to the Athar bot yet',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Open Telegram, tap Start, then "Share my number". '
            'Come back here and tap Send code again.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onOpenBot, child: const Text('Open Telegram')),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Send code again'),
          ),
        ],
      ),
    );
  }
}
