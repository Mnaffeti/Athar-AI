import 'dart:math';

import '../models/app_usage.dart';

/// Pure screen-time math. Every number in a report comes from here, never from the LLM.

const blockLabels = ['0-4', '4-8', '8-12', '12-16', '16-20', '20-24'];
const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String blockRange(int i) =>
    '${(i * 4).toString().padLeft(2, '0')}:00–${((i + 1) * 4).toString().padLeft(2, '0')}:00';

String weekdayName(String date) => _weekdayNames[DateTime.parse(date).weekday - 1];

/// "2h 05m" or "45m".
String formatMinutes(double m) {
  final total = m.round();
  final h = total ~/ 60, min = total % 60;
  return h == 0 ? '${min}m' : '${h}h ${min.toString().padLeft(2, '0')}m';
}

class AppShare {
  const AppShare(this.label, this.minPerDay, this.sharePct);
  final String label;
  final double minPerDay;
  final double sharePct;
}

class UsageSummary {
  const UsageSummary({
    required this.dailyTotals,
    required this.topApps,
    required this.blocks,
    required this.weekdayAvg,
    required this.weekendAvg,
    required this.changePct,
    required this.forecast,
  });

  /// date → minutes, sorted by date; days without data are absent.
  final Map<String, double> dailyTotals;

  /// Up to 5 named apps, then "Other" if anything is left.
  final List<AppShare> topApps;

  /// 6 four-hour blocks, average minutes per day.
  final List<double> blocks;
  final double weekdayAvg, weekendAvg, changePct;

  /// Next week: "Total" first, then the top 3 apps.
  final List<Prediction> forecast;

  int get days => dailyTotals.length;
  String get periodStart => dailyTotals.keys.first;
  String get periodEnd => dailyTotals.keys.last;
  Set<String> get appNames =>
      {for (final a in topApps) if (a.label != 'Other') a.label};
  int get peakBlock => blocks.indexOf(blocks.reduce(max));
}

UsageSummary summarize(List<AppUsageDay> rows) {
  final dates = {for (final r in rows) r.date}.toList()..sort();
  final days = max(dates.length, 1);

  final dailyTotals = {for (final d in dates) d: 0.0};
  final appTotals = <String, double>{};
  final appDaily = <String, Map<String, double>>{};
  final hourly = List<double>.filled(24, 0);
  for (final r in rows) {
    dailyTotals[r.date] = dailyTotals[r.date]! + r.minutes;
    appTotals[r.label] = (appTotals[r.label] ?? 0) + r.minutes;
    (appDaily[r.label] ??= {})[r.date] = (appDaily[r.label]?[r.date] ?? 0) + r.minutes;
    for (var h = 0; h < 24 && h < r.hourly.length; h++) {
      hourly[h] += r.hourly[h];
    }
  }

  final grand = appTotals.values.fold(0.0, (a, b) => a + b);
  final ranked = appTotals.entries.where((e) => e.value >= 1).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final named = ranked.take(5).toList();
  final other = grand - named.fold(0.0, (a, e) => a + e.value);
  AppShare share(String label, double total) =>
      AppShare(label, total / days, grand == 0 ? 0 : total / grand * 100);
  final topApps = [
    for (final e in named) share(e.key, e.value),
    if (other > 0.5) share('Other', other),
  ];

  final blocks = [
    for (var b = 0; b < 6; b++)
      hourly.sublist(b * 4, b * 4 + 4).fold(0.0, (a, v) => a + v) / days,
  ];

  double avg(Iterable<double> v) =>
      v.isEmpty ? 0 : v.fold(0.0, (a, b) => a + b) / v.length;
  bool weekend(String d) => DateTime.parse(d).weekday >= DateTime.saturday;

  final values = [for (final d in dates) dailyTotals[d]!];
  final half = values.length ~/ 2;
  final firstAvg = avg(values.take(half));
  final secondAvg = avg(values.skip(values.length - half));
  final changePct = half == 0 || firstAvg == 0
      ? 0.0
      : (secondAvg / firstAvg - 1) * 100;

  return UsageSummary(
    dailyTotals: dailyTotals,
    topApps: topApps,
    blocks: blocks,
    weekdayAvg: avg([for (final d in dates) if (!weekend(d)) dailyTotals[d]!]),
    weekendAvg: avg([for (final d in dates) if (weekend(d)) dailyTotals[d]!]),
    changePct: changePct,
    forecast: [
      forecastWeek('Total', values),
      for (final e in named.take(3))
        forecastWeek(e.key, [for (final d in dates) appDaily[e.key]![d] ?? 0]),
    ],
  );
}

/// Next week's minutes: mean × 7, range ±1 SD × √7, never below 0.
Prediction forecastWeek(String subject, List<double> daily) {
  if (daily.isEmpty) return Prediction(subject, 0, 0, 0);
  final mean = daily.fold(0.0, (a, b) => a + b) / daily.length;
  final variance =
      daily.fold(0.0, (a, v) => a + (v - mean) * (v - mean)) / daily.length;
  final spread = sqrt(variance) * sqrt(7);
  final week = mean * 7;
  return Prediction(subject, week, max(0, week - spread), week + spread);
}

/// Rule-based report used when the AI is unavailable (spec FR-007).
BehaviourReport offlineReport(UsageSummary s, {DateTime? now}) {
  final top = s.topApps.firstWhere(
    (a) => a.label != 'Other',
    orElse: () => const AppShare('your phone', 0, 0),
  );
  final busiest = s.dailyTotals.entries.reduce((a, b) => b.value > a.value ? b : a);
  final peak = s.peakBlock;
  final change = s.changePct.round();
  return BehaviourReport(
    generatedAt: now ?? DateTime.now(),
    periodStart: s.periodStart,
    periodEnd: s.periodEnd,
    patterns: [
      'Your top app is ${top.label} at ${formatMinutes(top.minPerDay)} per day '
          '(${top.sharePct.round()}% of your screen time).',
      'Your busiest day was ${weekdayName(busiest.key)} with ${formatMinutes(busiest.value)}.',
      change.abs() < 1
          ? 'Your screen time stayed steady across the period.'
          : 'Your screen time is ${change > 0 ? 'up' : 'down'} ${change.abs()}% '
                'in the second half of the period.',
    ],
    predictions: s.forecast,
    riskyTimes: [
      '${blockRange(peak)}: ${formatMinutes(s.blocks[peak])} per day on average.',
    ],
    suggestions: [
      'Set a daily limit for ${top.label} a little below ${formatMinutes(top.minPerDay)}.',
      'Keep your phone out of reach during ${blockRange(peak)}.',
      'Plan one phone-free activity on ${weekdayName(busiest.key)}s.',
    ],
    source: 'offline',
    dailyTotals: s.dailyTotals,
    blocks: s.blocks,
  );
}
