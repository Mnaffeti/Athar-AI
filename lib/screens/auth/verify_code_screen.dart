import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/onboarding_answers.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../main_shell.dart';
import '../onboarding/quiz_screen.dart';

/// Enter the 6-digit code sent by email or Telegram.
class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({
    super.key,
    required this.destination,
    required this.resend,
    required this.verify,
    this.answers,
  });

  /// Shown to the user, e.g. "you@email.com".
  final String destination;
  final Future<void> Function() resend;
  final Future<void> Function(String code) verify;

  /// Quiz answers from onboarding; saved to a new account.
  final OnboardingAnswers? answers;

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  static const _cooldown = 60;

  final _codeController = TextEditingController();
  Timer? _timer;
  int _secondsLeft = _cooldown;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) t.cancel();
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _resend() async {
    setState(() => _error = null);
    try {
      await widget.resend();
      _startCooldown();
    } catch (e) {
      setState(() => _error = AuthService.errorMessage(e, sending: true));
    }
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.verify(_codeController.text);
      final answers = widget.answers;
      final profile = await AuthService.loadProfile();
      if (profile == null && answers != null) {
        await AuthService.saveProfile(answers);
      }
      if (!mounted) return;
      final home = profile ?? answers;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              home == null ? const QuizScreen() : MainShell(profile: home),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AuthService.errorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canVerify = !_loading && _codeController.text.length == 6;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const Text(
              'Enter your code',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                text: 'We sent a 6-digit code to ',
                children: [
                  TextSpan(
                    text: widget.destination,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  const TextSpan(text: '. It expires in 5 minutes.'),
                ],
              ),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, letterSpacing: 12),
              decoration: const InputDecoration(hintText: '······'),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => canVerify ? _verify() : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.alert, fontSize: 14),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: canVerify ? _verify : null,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.onAccent,
                      ),
                    )
                  : const Text('Verify'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Change'),
                ),
                TextButton(
                  onPressed: _secondsLeft > 0 || _loading ? null : _resend,
                  child: Text(
                    _secondsLeft > 0 ? 'Resend in ${_secondsLeft}s' : 'Resend',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Didn't get it? Check your spam folder, or go back and try the other option.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
