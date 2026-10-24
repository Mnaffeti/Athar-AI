import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'onboarding/welcome_screen.dart';

/// Animated brand splash shown right after the native launch screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final _logoScale = Tween(begin: 0.85, end: 1.0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
    ),
  );
  late final _logoFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.45, curve: Curves.easeOut),
  );
  late final _taglineFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.55, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2400), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) => const WelcomeScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Image.asset('assets/images/logo_full.png', width: 280),
              ),
            ),
            const SizedBox(height: 40),
            FadeTransition(
              opacity: _taglineFade,
              child: Text(
                'For bad habits',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 1.2,
                  color: AppColors.brandLight.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
