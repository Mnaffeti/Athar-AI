import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/device_usage_service.dart';
import '../theme/app_theme.dart';

class SampleDataNote extends StatelessWidget {
  const SampleDataNote({super.key});

  @override
  Widget build(BuildContext context) {
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Chip(
          label: Text('Sample data'),
          visualDensity: VisualDensity.compact,
        ),
        if (android)
          const TextButton(
            onPressed: DeviceUsageService.openUsageAccessSettings,
            child: Text('Grant usage access'),
          )
        else
          const Text(
            'Real data needs the Android app.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
      ],
    );
  }
}
