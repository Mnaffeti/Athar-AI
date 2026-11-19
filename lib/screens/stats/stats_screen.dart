import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/daily_tracking.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bar_chart.dart';
import '../../widgets/stat_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.tracking});
  final DailyTracking tracking;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Metric _selected = MockData.screenTime;

  Metric _todayMetric(Metric demo, double today) {
    final week = List<double>.of(demo.week);
    week[week.length - 1] = today;
    return demo.copyWith(today: today, week: week);
  }

  List<Metric> get _metrics => [
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
          const _InsightCard(),
          const SizedBox(height: 14),
          const _AppBreakdown(),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.accentDim,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: AppColors.accent),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your screen time dropped 35% since Monday. '
              'Fridays are your best day — try copying that routine on Saturday.',
              style: TextStyle(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBreakdown extends StatelessWidget {
  const _AppBreakdown();

  @override
  Widget build(BuildContext context) {
    const apps = MockData.appBreakdown;
    final max = apps.map((a) => a.$2).reduce((a, b) => a > b ? a : b);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top apps today',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          for (final (name, hours, color) in apps)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: Text(
                      name,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: hours / max,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceHigh,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${(hours * 60).round()}m',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
