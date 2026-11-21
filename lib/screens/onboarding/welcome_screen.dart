import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../auth/sign_in_screen.dart';
import 'quiz_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Logo(),
              const Spacer(),
              const Text.rich(
                TextSpan(
                  text: 'Take back\nyour time',
                  children: [
                    TextSpan(
                      text: '.',
                      style: TextStyle(color: AppColors.brandRed),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 48,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Track your scrolling, screen time and gym hours. '
                'Athar builds a plan to help you swap the feed for real life.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              const _PreviewStats(),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const QuizScreen())),
                child: const Text('Get started'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SignInScreen(isReturningUser: true),
                  ),
                ),
                child: const Text('Log in with OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Image.asset('assets/images/logo_full.png', height: 44),
    );
  }
}

class _PreviewStats extends StatelessWidget {
  const _PreviewStats();

  @override
  Widget build(BuildContext context) {
    Widget pill(String value, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );

    return Row(
      children: [
        pill('-42%', 'screen time'),
        const SizedBox(width: 10),
        pill('+3h', 'phone-free/day'),
        const SizedBox(width: 10),
        pill('4×', 'gym per week'),
      ],
    );
  }
}
