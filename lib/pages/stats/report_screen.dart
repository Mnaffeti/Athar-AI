import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../models/app_usage.dart';
import '../../services/behaviour_report_service.dart';
import '../../services/usage_insights.dart';
import '../../theme/app_theme.dart';
import '../../atoms/app_card.dart';
import '../../components/week_bar_chart.dart';
import '../../atoms/bullet_text.dart';
import '../../atoms/card_title.dart';
import '../../components/report_section.dart';

/// The behaviour report: patterns, next-week predictions, risky times, suggestions.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.report});
  final BehaviourReport report;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _chartKey = GlobalKey();
  late BehaviourReport _report = widget.report;
  bool _sending = false;
  String? _sendMessage;
  bool _sendFailed = false;

  String _hours(double minutes) =>
      '${(minutes / 60).toStringAsFixed(minutes < 600 ? 1 : 0)}h';

  Future<void> _sendToTelegram() async {
    setState(() {
      _sending = true;
      _sendMessage = null;
    });
    final boundary =
        _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    final image = await boundary?.toImage(pixelRatio: 2);
    final png = await image?.toByteData(format: ui.ImageByteFormat.png);
    final error = await BehaviourReportService.sendToTelegram(
      _report,
      png?.buffer.asUint8List(),
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sendFailed = error != null;
      _sendMessage = switch (error) {
        null => 'Sent to Telegram',
        TelegramSendError.notLinked =>
          "Your number isn't linked to the Athar bot. Open Telegram, start "
              '@AtharccBot and share your number.',
        TelegramSendError.blocked =>
          'Unblock @AtharccBot in Telegram, then try again.',
        TelegramSendError.failed =>
          "Couldn't send right now. Your report is still saved here.",
      };
      if (error == null) _report = _report.markSent(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    final days = r.dailyTotals.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Your report')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${r.periodStart} → ${r.periodEnd}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              if (r.sample)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Chip(
                    label: Text('Sample data'),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (r.isOffline)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Chip(
                    label: Text('Offline summary'),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ReportSection(title: 'Patterns', items: r.patterns),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardTitle('Next week'),
                for (final p in r.predictions)
                  BulletText(
                    '${p.subject}: ~${_hours(p.mean)} '
                    '(${_hours(p.low)}–${_hours(p.high)})'
                    '${p.note == null ? '' : '. ${p.note}'}',
                  ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  key: _chartKey,
                  child: Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.all(8),
                    child: WeekBarChart(
                      values: [for (final d in days) r.dailyTotals[d]! / 60],
                      labels: [for (final d in days) weekdayName(d)],
                      color: AppColors.screen,
                      height: 160,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hours of screen time per day',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardTitle('Risky times'),
                for (final t in r.riskyTimes) BulletText(t),
                const SizedBox(height: 16),
                WeekBarChart(
                  values: r.blocks,
                  labels: blockLabels,
                  color: AppColors.scroll,
                  height: 140,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Average minutes per day, by time of day',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ReportSection(title: 'Try this', items: r.suggestions),
          if (BehaviourReportService.canSendToTelegram) ...[
            FilledButton.icon(
              onPressed: _sending ? null : _sendToTelegram,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onAccent,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                r.sentToTelegramAt == null ? 'Send to Telegram' : 'Send again',
              ),
            ),
            if (_sendMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _sendMessage!,
                style: TextStyle(
                  color: _sendFailed ? AppColors.alert : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
