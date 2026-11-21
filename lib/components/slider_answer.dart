import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SliderAnswer extends StatelessWidget {
  const SliderAnswer({super.key, 
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.footnote,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final String suffix;
  final String Function(double) footnote;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value.round().toString(),
              style: const TextStyle(
                fontSize: 96,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
                letterSpacing: -4,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              suffix,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.surfaceHigh,
            thumbColor: AppColors.textPrimary,
            overlayColor: AppColors.accent.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          footnote(value),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ],
    );
  }
}
