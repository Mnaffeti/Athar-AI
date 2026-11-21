import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnalysingView extends StatelessWidget {
  const AnalysingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 5,
              color: AppColors.accent,
              backgroundColor: AppColors.surfaceHigh,
            ),
          ),
          SizedBox(height: 28),
          Text(
            'Building your plan…',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Analysing your habits',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
