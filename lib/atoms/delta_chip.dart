import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';

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
