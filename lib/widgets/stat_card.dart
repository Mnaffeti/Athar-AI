import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import 'bar_chart.dart';

/// Base rounded surface used by every dashboard widget.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

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

class MetricIcon extends StatelessWidget {
  const MetricIcon({super.key, required this.metric, this.size = 36});

  final Metric metric;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: metric.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(metric.icon, color: metric.color, size: size * 0.55),
    );
  }
}

/// "▼ 12%" chip, green when the change is in the good direction.
class DeltaChip extends StatelessWidget {
  const DeltaChip({super.key, required this.metric});

  final Metric metric;

  @override
  Widget build(BuildContext context) {
    final delta = metric.deltaVsYesterday;
    final good = metric.lowerIsBetter ? delta <= 0 : delta >= 0;
    final color = good ? AppColors.accent : AppColors.alert;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${delta <= 0 ? '▼' : '▲'} ${(delta.abs() * 100).round()}%',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
