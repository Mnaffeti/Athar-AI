import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Selectable answer row used in the onboarding quiz.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emoji,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentDim : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: selected ? 1 : 0,
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
