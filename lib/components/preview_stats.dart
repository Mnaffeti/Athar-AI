import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PreviewStats extends StatelessWidget {
  const PreviewStats({super.key});

  @override
  Widget build(BuildContext context) {
    Widget pill(String value, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 2),
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
        pill('-42%', 'screen time'),
        const SizedBox(width: 10),
        pill('+3h', 'phone-free/day'),
        const SizedBox(width: 10),
        pill('4×', 'gym per week'),
      ],
    );
  }
}
