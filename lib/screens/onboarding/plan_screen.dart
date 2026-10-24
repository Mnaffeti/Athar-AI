import 'package:flutter/material.dart';

import '../../models/onboarding_answers.dart';
import '../../theme/app_theme.dart';
import '../auth/sign_in_screen.dart';

/// Shows a short "analysing" state, then reveals the personalised plan.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, required this.answers});

  final OnboardingAnswers answers;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _loading
              ? const _Analysing(key: ValueKey('loading'))
              : _Plan(key: const ValueKey('plan'), answers: widget.answers),
        ),
      ),
    );
  }
}

class _Analysing extends StatelessWidget {
  const _Analysing({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 5,
              color: AppColors.accent,
              backgroundColor: AppColors.surfaceHigh,
            ),
          ),
          SizedBox(height: 28),
          Text(
            'Building your plan…',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Analysing your habits',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Plan extends StatelessWidget {
  const _Plan({super.key, required this.answers});

  final OnboardingAnswers answers;

  @override
  Widget build(BuildContext context) {
    final a = answers;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              children: [
                Text(
                  '${a.name}, your plan is ready.',
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 32,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Goal: ${a.goal}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "You'll reclaim",
                        style: TextStyle(
                          color: AppColors.onAccent,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${a.hoursReclaimedPerYear} hours',
                        style: const TextStyle(
                          color: AppColors.onAccent,
                          fontFamily: AppFonts.display,
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Text(
                        'every year by following this plan.',
                        style: TextStyle(
                          color: AppColors.onAccent,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _PlanRow(
                  icon: Icons.smartphone_rounded,
                  color: AppColors.screen,
                  title: 'Screen time',
                  value:
                      '${a.dailyScreenHours.round()}h → ${a.targetScreenHours.round()}h / day',
                ),
                _PlanRow(
                  icon: Icons.forum_rounded,
                  color: AppColors.social,
                  title: 'Limit ${a.worstApps.take(2).join(' & ')}',
                  value: '1h 30m / day',
                ),
                _PlanRow(
                  icon: Icons.do_not_disturb_on_rounded,
                  color: AppColors.phoneFree,
                  title: 'Phone-free time',
                  value: '${a.phoneFreeGoalHours.round()}h / day',
                ),
                _PlanRow(
                  icon: Icons.fitness_center_rounded,
                  color: AppColors.gym,
                  title: 'Gym sessions',
                  value: '${a.weeklyGymGoal}× / week',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => SignInScreen(answers: a))),
            child: const Text('Save my plan'),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
