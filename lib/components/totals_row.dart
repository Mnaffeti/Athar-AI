import 'package:flutter/material.dart';
import '../atoms/app_card.dart';
import '../data/mock_data.dart';
import '../models/daily_tracking.dart';
import '../theme/app_theme.dart';

class TotalsRow extends StatelessWidget {
  const TotalsRow({super.key, required this.tracking});
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
