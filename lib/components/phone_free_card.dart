import 'package:flutter/material.dart';
import '../atoms/app_card.dart';
import '../atoms/metric_icon.dart';
import '../data/mock_data.dart';
import '../models/daily_tracking.dart';
import '../theme/app_theme.dart';

/// Phone-free progress + a button to start a focus session.
class PhoneFreeCard extends StatelessWidget {
  const PhoneFreeCard({super.key, required this.tracking});
  final DailyTracking tracking;

  @override
  Widget build(BuildContext context) {
    final m = MockData.phoneFree.copyWith(today: tracking.phoneFreeHours);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MetricIcon(metric: m),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Phone-free today',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${m.format(m.today)} / ${m.format(m.goal)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: m.progress.clamp(0, 1).toDouble(),
              minHeight: 10,
              backgroundColor: AppColors.surfaceHigh,
              color: m.color,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Focus sessions are coming soon')),
            ),
            icon: const Icon(Icons.lock_clock_rounded),
            label: const Text('Start phone-free session'),
          ),
        ],
      ),
    );
  }
}
