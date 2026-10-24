import 'package:flutter/material.dart';

import '../../models/onboarding_answers.dart';
import '../../theme/app_theme.dart';
import '../main_shell.dart';

/// Mocked sign-in: every button just enters the app. Wire real auth here later.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.answers, this.isReturningUser = false});

  /// Quiz answers for new users; returning users get a demo profile.
  final OnboardingAnswers? answers;
  final bool isReturningUser;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            MainShell(profile: widget.answers ?? OnboardingAnswers.demo()),
      ),
      (_) => false,
    );
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
            _SocialButton(
              icon: Icons.apple,
              label: 'Continue with Apple',
              onPressed: _loading ? null : _signIn,
            ),
            const SizedBox(height: 12),
            _SocialButton(
              icon: Icons.g_mobiledata_rounded,
              label: 'Continue with Google',
              onPressed: _loading ? null : _signIn,
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
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'you@email.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading || !_emailController.text.contains('@')
                  ? null
                  : _signIn,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.onAccent,
                      ),
                    )
                  : const Text('Continue with email'),
            ),
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

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 26),
      label: Text(label),
    );
  }
}
