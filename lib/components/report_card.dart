import 'package:flutter/material.dart';
import '../models/app_usage.dart';
import '../services/behaviour_report_service.dart';
import '../services/usage_insights.dart';
import '../theme/app_theme.dart';

/// "Your report" card: generate, view, or wait for enough data (contracts/stats-ui.md).
class ReportCard extends StatelessWidget {
  const ReportCard({super.key, 
    required this.summary,
    required this.sample,
    required this.latest,
    required this.generating,
    required this.onGenerate,
    required this.onOpen,
  });

  final UsageSummary summary;
  final bool sample;
  final BehaviourReport? latest;
  final bool generating;
  final VoidCallback onGenerate;
  final ValueChanged<BehaviourReport> onOpen;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final report = latest;
    final missing = BehaviourReportService.minDays - s.days;
    final wait = BehaviourReportService.cooldownLeft(report);

    final String text;
    Widget? action;
    if (missing > 0) {
      text =
          'Your report needs ${BehaviourReportService.minDays} days of data. '
          '$missing more ${missing == 1 ? 'day' : 'days'} to go.';
    } else {
      text = sample && report == null
          ? 'Preview the report with sample data. Real reports use your own '
                'screen time in the Android app.'
          : report == null
          ? 'Get patterns, a forecast for next week and tips, based on your '
                'last ${s.days} days.'
          : 'Last report: ${report.generatedAt.toLocal().toString().substring(0, 16)}'
                '${report.sample ? ' (sample data)' : ''}';
      action = FilledButton(
        onPressed: generating || wait > Duration.zero ? null : onGenerate,
        child: generating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.onAccent,
                ),
              )
            : Text(
                wait > Duration.zero
                    ? 'Generate again in ${wait.inMinutes + 1} min'
                    : report == null
                    ? (sample ? 'Generate sample report' : 'Generate my report')
                    : 'Generate again',
              ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.accentDim,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.accent),
              SizedBox(width: 10),
              Text(
                'Your report',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(height: 1.45)),
          if (report != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => onOpen(report),
              child: const Text('View report'),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      ),
    );
  }
}
