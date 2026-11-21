import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../auth/sign_in_screen.dart';
import 'quiz_screen.dart';
import '../../atoms/app_logo.dart';
import '../../components/preview_stats.dart';

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
              const AppLogo(),
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
              const PreviewStats(),
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
