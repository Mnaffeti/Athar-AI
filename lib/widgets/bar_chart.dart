import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_theme.dart';

/// Simple 7-day bar chart. The last bar (today) is highlighted.
class WeekBarChart extends StatelessWidget {
  const WeekBarChart({
    super.key,
    required this.values,
    required this.color,
    this.height = 140,
    this.goal,
    this.showLabels = true,
    this.labels,
  });

  final List<double> values;
  final Color color;
  final double height;
  final double? goal;
  final bool showLabels;

  /// One label per bar; defaults to weekdays.
  final List<String>? labels;

  @override
  Widget build(BuildContext context) {
    final maxValue = [...values, goal ?? 0].reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue == 0 ? 1.0 : maxValue * 1.1;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chartHeight = constraints.maxHeight - (showLabels ? 22 : 0);
          return Stack(
            children: [
              if (goal != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: chartHeight - (goal! / safeMax) * chartHeight,
                  child: _DashedLine(color: AppColors.textMuted),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < values.length; i++)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: values[i] / safeMax),
                            duration: Duration(milliseconds: 500 + i * 60),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) => Container(
                              height: (v * chartHeight).clamp(4, chartHeight),
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: i == values.length - 1
                                    ? color
                                    : color.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          if (showLabels) ...[
                            const SizedBox(height: 6),
                            Text(
                              labels?[i] ?? MockData.weekdays[i % 7],
                              style: TextStyle(
                                fontSize: 12,
                                color: i == values.length - 1
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 8).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }
}
