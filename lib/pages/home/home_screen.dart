import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/daily_tracking.dart';
import '../../models/onboarding_answers.dart';
import '../../theme/app_theme.dart';
import '../../atoms/app_card.dart';
import '../../atoms/delta_chip.dart';
import '../../atoms/metric_icon.dart';
import '../../atoms/profile_avatar.dart';
import '../../atoms/progress_ring.dart';
import '../../components/metric_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.profile,
    required this.tracking,
    required this.onOpenStats,
    required this.onOpenProfile,
  });

  final OnboardingAnswers profile;
  final DailyTracking tracking;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _Header(profile: profile, onOpenProfile: onOpenProfile),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 18),
          _ScreenTimeHero(tracking: tracking),
          const SizedBox(height: 14),
          _ScrollCard(tracking: tracking),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MetricTile(
                  metric: MockData.socialMedia.copyWith(today: tracking.socialHours),
                  onTap: onOpenStats,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: MetricTile(
                  metric: MockData.gym.copyWith(today: tracking.gymHours),
                  onTap: onOpenStats,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _TotalsRow(tracking: tracking),
          const SizedBox(height: 14),
          _PhoneFreeCard(tracking: tracking),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.onOpenProfile});

  final OnboardingAnswers profile;
  final VoidCallback onOpenProfile;

  static const _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', //
    'Sunday',
  ];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    final date =
        '${_days[now.weekday - 1]}, ${_months[now.month - 1]} ${now.day}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$greeting,\n',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: profile.name ?? 'there'),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 30,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          label: '${MockData.streakDays} day streak',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: AppColors.scroll,
                ),
                SizedBox(width: 4),
                Text(
                  '${MockData.streakDays}',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        ProfileAvatar(initials: profile.initials, onTap: onOpenProfile),
      ],
    );
  }
}

/// Big ring showing screen time vs. daily limit.
class _ScreenTimeHero extends StatelessWidget {
  const _ScreenTimeHero({required this.tracking});
  final DailyTracking tracking;

  @override
  Widget build(BuildContext context) {
    final m = MockData.screenTime.copyWith(today: tracking.screenHours);
    final remaining = m.goal - m.today;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          ProgressRing(
            progress: m.today / m.goal,
            color: m.onTrack ? AppColors.accent : AppColors.alert,
            size: 124,
            stroke: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m.format(m.today),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'of ${m.format(m.goal)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Screen time today',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  remaining >= 0
                      ? '${m.format(remaining)} left'
                      : '${m.format(-remaining)} over',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: remaining >= 0
                        ? AppColors.textPrimary
                        : AppColors.screen,
                  ),
                ),
                const SizedBox(height: 10),
                DeltaChip(metric: m),
                const SizedBox(height: 6),
                const Text(
                  'vs. yesterday',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollCard extends StatelessWidget {
  const _ScrollCard({required this.tracking});
  final DailyTracking tracking;

  @override
  Widget build(BuildContext context) {
    final m = MockData.scroll.copyWith(today: tracking.scrollMinutes);
    return AppCard(
      child: Row(
        children: [
          MetricIcon(metric: m, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You scrolled',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  m.format(m.today),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  MockData.scrollComparison(m.today),
                  style: const TextStyle(fontSize: 13, color: AppColors.scroll),
                ),
              ],
            ),
          ),
          DeltaChip(metric: m),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.tracking});
  final DailyTracking tracking;

  @override
  Widget build(BuildContext context) {
    Widget total(String value, String label, IconData icon, Color color) =>
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 14),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
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
        total(
          '${MockData.totalGymHours}h',
          'Total in gym',
          Icons.fitness_center_rounded,
          AppColors.gym,
        ),
        const SizedBox(width: 14),
        total(
          '${MockData.totalPhoneFreeHours.round()}h',
          'Total without phone',
          Icons.do_not_disturb_on_rounded,
          AppColors.phoneFree,
        ),
      ],
    );
  }
}

/// Phone-free progress + a button to start a focus session.
class _PhoneFreeCard extends StatelessWidget {
  const _PhoneFreeCard({required this.tracking});
  final DailyTracking tracking;

  @override
  Widget build(BuildContext context) {
    final m = MockData.phoneFree.copyWith(today: tracking.phoneFreeHours);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MetricIcon(metric: m),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Phone-free today',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${m.format(m.today)} / ${m.format(m.goal)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: m.progress.clamp(0, 1).toDouble(),
              minHeight: 10,
              backgroundColor: AppColors.surfaceHigh,
              color: m.color,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Focus sessions are coming soon')),
            ),
            icon: const Icon(Icons.lock_clock_rounded),
            label: const Text('Start phone-free session'),
          ),
        ],
      ),
    );
  }
}
