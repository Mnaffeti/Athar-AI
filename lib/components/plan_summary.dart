import 'package:flutter/material.dart';
import '../models/onboarding_answers.dart';
import '../theme/app_theme.dart';
import 'plan_row.dart';

class PlanSummary extends StatelessWidget {
  const PlanSummary({super.key, required this.answers, required this.onSave});

  final OnboardingAnswers answers;

  /// Called with the button's context (sign-in or save, then navigate).
  final void Function(BuildContext context) onSave;

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
                PlanRow(
                  icon: Icons.smartphone_rounded,
                  color: AppColors.screen,
                  title: 'Screen time',
                  value:
                      '${a.dailyScreenHours.round()}h → ${a.targetScreenHours.round()}h / day',
                ),
                PlanRow(
                  icon: Icons.forum_rounded,
                  color: AppColors.social,
                  title: 'Limit ${a.worstApps.take(2).join(' & ')}',
                  value: '1h 30m / day',
                ),
                PlanRow(
                  icon: Icons.do_not_disturb_on_rounded,
                  color: AppColors.phoneFree,
                  title: 'Phone-free time',
                  value: '${a.phoneFreeGoalHours.round()}h / day',
                ),
                PlanRow(
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
            onPressed: () => onSave(context),
            child: const Text('Save my plan'),
          ),
        ],
      ),
    );
  }
}
