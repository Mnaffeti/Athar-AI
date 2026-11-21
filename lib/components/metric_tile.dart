import 'package:flutter/material.dart';
import '../atoms/app_card.dart';
import '../atoms/delta_chip.dart';
import '../atoms/metric_icon.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import 'week_bar_chart.dart';

/// Small square widget: icon, value, label, mini sparkline bars.
class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.metric, this.onTap});

  final Metric metric;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MetricIcon(metric: metric),
              const Spacer(),
              DeltaChip(metric: metric),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            metric.format(metric.today),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          WeekBarChart(
            values: metric.week,
            color: metric.color,
            height: 36,
            showLabels: false,
          ),
        ],
      ),
    );
  }
}
