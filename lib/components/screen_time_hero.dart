import 'package:flutter/material.dart';
import '../atoms/app_card.dart';
import '../atoms/delta_chip.dart';
import '../atoms/progress_ring.dart';
import '../data/mock_data.dart';
import '../models/daily_tracking.dart';
import '../theme/app_theme.dart';

/// Big ring showing screen time vs. daily limit.
class ScreenTimeHero extends StatelessWidget {
  const ScreenTimeHero({super.key, required this.tracking});
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
