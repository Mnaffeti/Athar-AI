import 'package:flutter/material.dart';
import '../atoms/app_card.dart';
import '../atoms/delta_chip.dart';
import '../atoms/metric_icon.dart';
import '../data/mock_data.dart';
import '../models/daily_tracking.dart';
import '../theme/app_theme.dart';

class ScrollCard extends StatelessWidget {
  const ScrollCard({super.key, required this.tracking});
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
