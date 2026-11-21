import 'package:flutter_test/flutter_test.dart';
import 'package:quit/data/mock_data.dart';
import 'package:quit/models/app_usage.dart';
import 'package:quit/services/usage_insights.dart';

List<double> at(int hour, double minutes) =>
    List.generate(24, (h) => h == hour ? minutes : 0.0);

AppUsageDay row(String date, String app, double min, {int hour = 21}) =>
    AppUsageDay(date: date, package: 'p.$app', label: app, minutes: min, hourly: at(hour, min));

// Thu 2026-11-19, Fri 20, Sat 21.
final fixture = [
  row('2026-11-19', 'Instagram', 60),
  row('2026-11-19', 'YouTube', 30, hour: 13),
  row('2026-11-20', 'Instagram', 90),
  row('2026-11-21', 'Instagram', 120),
  row('2026-11-21', 'Maps', 0.4), // under 1 min → Other
  for (final a in ['A', 'B', 'C', 'D']) row('2026-11-21', a, 2),
];

void main() {
  final s = summarize(fixture);

  test('daily totals and days', () {
    expect(s.days, 3);
    expect(s.dailyTotals['2026-11-19'], 90);
    expect(s.dailyTotals['2026-11-21'], closeTo(128.4, 1e-9));
    expect(s.periodStart, '2026-11-19');
    expect(s.periodEnd, '2026-11-21');
  });

  test('top 5 then Other, shares sum to 100', () {
    expect(s.topApps.length, 6);
    expect(s.topApps.first.label, 'Instagram');
    expect(s.topApps.first.minPerDay, 90);
    expect(s.topApps.last.label, 'Other');
    expect(s.appNames.contains('Maps'), isFalse);
    final sum = s.topApps.fold(0.0, (a, x) => a + x.sharePct);
    expect(sum, closeTo(100, 1e-6));
  });

  test('4-hour blocks average per day', () {
    expect(s.blocks[3], closeTo(10, 1e-9)); // 30 min at 13:00 / 3 days
    expect(s.peakBlock, 5); // 20-24
  });

  test('weekday vs weekend and change', () {
    expect(s.weekdayAvg, 90); // Thu 90, Fri 90
    expect(s.weekendAvg, closeTo(128.4, 1e-9));
    expect(s.changePct, closeTo((128.4 / 90 - 1) * 100, 1e-6));
  });

  test('forecast has a range and never goes below zero', () {
    final total = s.forecast.first;
    expect(total.subject, 'Total');
    expect(total.mean, closeTo((90 + 90 + 128.4) / 3 * 7, 1e-6));
    expect(total.low, lessThan(total.mean));
    expect(total.high, greaterThan(total.mean));
    final spiky = forecastWeek('X', [0, 0, 0, 0, 0, 0, 600]);
    expect(spiky.low, greaterThanOrEqualTo(0));
    expect(spiky.high, greaterThan(spiky.mean));
    expect(s.forecast.length, 4); // Total + top 3
  });

  test('sample usage covers 7 days and the demo apps', () {
    final sample = summarize(MockData.sampleUsage(today: DateTime(2026, 11, 21)));
    expect(sample.days, 7);
    expect(sample.periodEnd, '2026-11-21');
    expect(sample.appNames, containsAll(['Instagram', 'TikTok', 'YouTube', 'X']));
    expect(sample.peakBlock, 5); // evenings
    final r = offlineReport(sample).asSample();
    expect(BehaviourReport.fromJson(r.toJson()).sample, isTrue);
  });

  test('offline report names only real apps', () {
    final r = offlineReport(s, now: DateTime(2026, 11, 21, 22));
    expect(r.source, 'offline');
    expect(r.patterns.first, contains('Instagram'));
    expect(r.patterns[1], contains('Sat'));
    expect(r.riskyTimes.single, startsWith('20:00–24:00'));
    expect(r.suggestions.length, 3);
    expect(BehaviourReport.fromJson(r.toJson()).toJson(), r.toJson());
  });
}
