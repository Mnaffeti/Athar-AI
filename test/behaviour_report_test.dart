import 'package:flutter_test/flutter_test.dart';
import 'package:quit/models/app_usage.dart';
import 'package:quit/services/behaviour_report_service.dart';
import 'package:quit/services/usage_insights.dart';

AppUsageDay row(String date, String app, double min) => AppUsageDay(
  date: date,
  package: 'p.$app',
  label: app,
  minutes: min,
  hourly: List.generate(24, (h) => h == 21 ? min : 0.0),
);

final summary = summarize([
  row('2026-11-19', 'Instagram', 60),
  row('2026-11-20', 'Instagram', 90),
  row('2026-11-21', 'YouTube', 120),
]);

Map<String, dynamic> reply() => {
  'patterns': ['Instagram takes 50 min a day.', 'TikTok is rising fast.', 'Nights are your peak.'],
  'prediction_notes': {'Total': 'Similar to this week.', 'Instagram': 'Slightly down.'},
  'risky_times': ['20:00–24:00: 90 min/day.'],
  'suggestions': ['One', 'Two', 'Three', 'Four'],
};

void main() {
  test('drops lines naming apps not in the data', () {
    final r = BehaviourReportService.validate(reply(), summary)!;
    expect(r.patterns, ['Instagram takes 50 min a day.', 'Nights are your peak.']);
    expect(r.source, 'ai');
    expect(r.suggestions, ['One', 'Two', 'Three']);
  });

  test('prediction numbers come from the forecast, notes from the reply', () {
    final r = BehaviourReportService.validate(reply(), summary)!;
    expect(r.predictions.first.mean, summary.forecast.first.mean);
    expect(r.predictions.first.low, summary.forecast.first.low);
    expect(r.predictions.first.note, 'Similar to this week.');
    expect(r.predictions.length, summary.forecast.length);
  });

  test('rejects replies with missing keys or too few items', () {
    expect(BehaviourReportService.validate(reply()..remove('risky_times'), summary), isNull);
    expect(BehaviourReportService.validate(reply()..['suggestions'] = ['a', 'b'], summary), isNull);
    expect(BehaviourReportService.validate(reply()..['patterns'] = 'not a list', summary), isNull);
  });

  test('report JSON round-trip and Telegram text', () {
    final r = BehaviourReportService.validate(reply(), summary)!;
    expect(BehaviourReport.fromJson(r.toJson()).toJson(), r.toJson());
    final text = BehaviourReportService.asText(r);
    expect(text, contains('Next week'));
    expect(text.length, lessThanOrEqualTo(4000));
  });

  test('cooldown is one hour from generation', () {
    final r = offlineReport(summary, now: DateTime(2026, 11, 21, 10));
    expect(BehaviourReportService.cooldownLeft(r, now: DateTime(2026, 11, 21, 10, 20)),
        const Duration(minutes: 40));
    expect(BehaviourReportService.cooldownLeft(r, now: DateTime(2026, 11, 21, 11, 1)), Duration.zero);
  });
}
