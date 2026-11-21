import 'package:flutter/material.dart';
import '../atoms/app_card.dart';
import '../data/mock_data.dart';
import '../services/usage_insights.dart';
import '../theme/app_theme.dart';

class AppBreakdown extends StatelessWidget {
  const AppBreakdown({super.key, required this.summary});
  final UsageSummary? summary;

  static const _palette = [
    AppColors.social,
    AppColors.screen,
    AppColors.scroll,
    AppColors.gym,
    AppColors.accent,
    AppColors.textSecondary,
  ];

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final apps = s == null
        ? MockData.appBreakdown
        : [
            for (var i = 0; i < s.topApps.length; i++)
              (s.topApps[i].label, s.topApps[i].minPerDay / 60, _palette[i % _palette.length]),
          ];
    if (apps.isEmpty) return const SizedBox.shrink();
    final max = apps.map((a) => a.$2).reduce((a, b) => a > b ? a : b);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s == null ? 'Top apps today' : 'Top apps (daily average)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          for (final (name, hours, color) in apps)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: Text(
                      name,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: hours / max,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceHigh,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${(hours * 60).round()}m',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
