import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/app_usage.dart';
import '../../models/daily_tracking.dart';
import '../../services/behaviour_report_service.dart';
import '../../services/device_usage_service.dart';
import '../../services/usage_insights.dart';
import '../../theme/app_theme.dart';
import 'report_screen.dart';
import '../../atoms/app_card.dart';
import '../../atoms/metric_icon.dart';
import '../../components/week_bar_chart.dart';
import '../../components/app_breakdown.dart';
import '../../components/report_card.dart';
import '../../components/sample_data_note.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.tracking, this.goal});
  final DailyTracking tracking;

  /// Onboarding goal, passed to the report (spec FR-005d).
  final String? goal;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with WidgetsBindingObserver {
  Metric _selected = MockData.screenTime;

  /// Real per-app usage; null means sample data (web, iOS, no usage access).
  UsageSummary? _summary;
  late final _sampleSummary = summarize(MockData.sampleUsage());
  BehaviourReport? _latest;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Back from the usage-access settings screen: pick up the new data.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final rows = await DeviceUsageService.readAppUsage();
    final latest = await BehaviourReportService.loadLatest();
    if (!mounted) return;
    setState(() {
      _summary = rows == null || rows.isEmpty ? null : summarize(rows);
      _latest = latest;
    });
  }

  Future<void> _generate() async {
    if (!await BehaviourReportService.hasConsent()) {
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Write my report?'),
          content: const Text(
            'To write your report, Athar sends app names, minutes and times of '
            "day to Groq's AI. No name, email or phone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await BehaviourReportService.giveConsent();
    }
    setState(() => _generating = true);
    final report = await BehaviourReportService.generate(
      _summary ?? _sampleSummary,
      goal: widget.goal,
      sample: _summary == null,
    );
    if (!mounted) return;
    setState(() {
      _generating = false;
      _latest = report;
    });
    _open(report);
  }

  Future<void> _open(BehaviourReport report) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReportScreen(report: report)),
    );
    _load(); // the report may have been marked as sent
  }

  Metric _todayMetric(Metric demo, double today) {
    final week = List<double>.of(demo.week);
    week[week.length - 1] = today;
    return demo.copyWith(today: today, week: week);
  }

  List<Metric> get _metrics => [
    if (_summary case final s?)
      MockData.screenTime.copyWith(
        week: [for (final m in s.dailyTotals.values) m / 60],
        today: s.dailyTotals.values.last / 60,
      )
    else
      _todayMetric(MockData.screenTime, widget.tracking.screenHours),
    _todayMetric(MockData.scroll, widget.tracking.scrollMinutes),
    _todayMetric(MockData.socialMedia, widget.tracking.socialHours),
    _todayMetric(MockData.gym, widget.tracking.gymHours),
    _todayMetric(MockData.phoneFree, widget.tracking.phoneFreeHours),
  ];

  @override
  Widget build(BuildContext context) {
    final metrics = _metrics;
    final m = metrics.firstWhere(
      (metric) => metric.id == _selected.id,
      orElse: () => metrics.first,
    );
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const Text(
            'This week',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          if (_summary == null) ...[
            const SizedBox(height: 8),
            const SampleDataNote(),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: metrics.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final metric = metrics[i];
                final selected = metric.id == m.id;
                return ChoiceChip(
                  label: Text(metric.label),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _selected = metric),
                  backgroundColor: AppColors.surface,
                  selectedColor: metric.color.withValues(alpha: 0.18),
                  side: BorderSide(
                    color: selected ? metric.color : AppColors.border,
                  ),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MetricIcon(metric: m),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily average',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            m.format(m.weekTotal / m.week.length),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Week total',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          m.format(m.weekTotal),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                WeekBarChart(
                  key: ValueKey(m.id),
                  values: m.week,
                  labels: m.id == 'screen' && _summary != null
                      ? [for (final d in _summary!.dailyTotals.keys) weekdayName(d)]
                      : null,
                  color: m.color,
                  goal: m.goal,
                  height: 180,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(width: 14, height: 1, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Daily ${m.lowerIsBetter ? 'limit' : 'goal'}: ${m.format(m.goal)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ReportCard(
            summary: _summary ?? _sampleSummary,
            sample: _summary == null,
            latest: _latest,
            generating: _generating,
            onGenerate: _generate,
            onOpen: _open,
          ),
          const SizedBox(height: 14),
          AppBreakdown(summary: _summary),
        ],
      ),
    );
  }
}
