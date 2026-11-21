/// One app's foreground time on one local day, from the Android usage channel.
class AppUsageDay {
  const AppUsageDay({
    required this.date,
    required this.package,
    required this.label,
    required this.minutes,
    required this.hourly,
  });

  factory AppUsageDay.fromMap(Map<dynamic, dynamic> m) => AppUsageDay(
    date: m['date'] as String,
    package: m['package'] as String,
    label: m['label'] as String,
    minutes: (m['minutes'] as num).toDouble(),
    hourly: [for (final v in m['hourly'] as List) (v as num).toDouble()],
  );

  final String date; // yyyy-MM-dd, local
  final String package;
  final String label;
  final double minutes;
  final List<double> hourly; // 24 values, minutes per local hour
}

/// A forecast for next week, in minutes; numbers always come from the data.
class Prediction {
  const Prediction(this.subject, this.mean, this.low, this.high, [this.note]);

  factory Prediction.fromJson(Map<String, dynamic> j) => Prediction(
    j['subject'] as String,
    (j['mean'] as num).toDouble(),
    (j['low'] as num).toDouble(),
    (j['high'] as num).toDouble(),
    j['note'] as String?,
  );

  final String subject; // "Total" or an app name
  final double mean, low, high;
  final String? note;

  Prediction withNote(String? note) => Prediction(subject, mean, low, high, note);

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'mean': mean,
    'low': low,
    'high': high,
    'note': note,
  };
}

class BehaviourReport {
  const BehaviourReport({
    required this.generatedAt,
    required this.periodStart,
    required this.periodEnd,
    required this.patterns,
    required this.predictions,
    required this.riskyTimes,
    required this.suggestions,
    required this.source,
    required this.dailyTotals,
    required this.blocks,
    this.sentToTelegramAt,
    this.sample = false,
  });

  factory BehaviourReport.fromJson(Map<String, dynamic> j) => BehaviourReport(
    generatedAt: DateTime.parse(j['generatedAt'] as String),
    periodStart: j['periodStart'] as String,
    periodEnd: j['periodEnd'] as String,
    patterns: (j['patterns'] as List).cast<String>(),
    predictions: [
      for (final p in j['predictions'] as List)
        Prediction.fromJson(Map<String, dynamic>.from(p as Map)),
    ],
    riskyTimes: (j['riskyTimes'] as List).cast<String>(),
    suggestions: (j['suggestions'] as List).cast<String>(),
    source: j['source'] as String,
    dailyTotals: Map<String, double>.from(
      (j['dailyTotals'] as Map).map(
        (k, v) => MapEntry(k as String, (v as num).toDouble()),
      ),
    ),
    blocks: [for (final v in j['blocks'] as List) (v as num).toDouble()],
    sentToTelegramAt: j['sentToTelegramAt'] == null
        ? null
        : DateTime.parse(j['sentToTelegramAt'] as String),
    sample: j['sample'] as bool? ?? false,
  );

  final DateTime generatedAt;
  final String periodStart, periodEnd;
  final List<String> patterns;
  final List<Prediction> predictions;
  final List<String> riskyTimes;
  final List<String> suggestions;
  final String source; // 'ai' or 'offline'
  /// Chart data kept with the report so it renders the same later.
  final Map<String, double> dailyTotals; // date → minutes
  final List<double> blocks; // 6 × 4h, avg minutes/day
  final DateTime? sentToTelegramAt;

  /// Built from demo data (web/iOS preview), not the user's usage.
  final bool sample;

  bool get isOffline => source == 'offline';

  BehaviourReport markSent(DateTime at) => _copy(sentToTelegramAt: at);
  BehaviourReport asSample() => _copy(sample: true);

  BehaviourReport _copy({DateTime? sentToTelegramAt, bool? sample}) => BehaviourReport(
    generatedAt: generatedAt,
    periodStart: periodStart,
    periodEnd: periodEnd,
    patterns: patterns,
    predictions: predictions,
    riskyTimes: riskyTimes,
    suggestions: suggestions,
    source: source,
    dailyTotals: dailyTotals,
    blocks: blocks,
    sentToTelegramAt: sentToTelegramAt ?? this.sentToTelegramAt,
    sample: sample ?? this.sample,
  );

  Map<String, dynamic> toJson() => {
    'generatedAt': generatedAt.toIso8601String(),
    'periodStart': periodStart,
    'periodEnd': periodEnd,
    'patterns': patterns,
    'predictions': [for (final p in predictions) p.toJson()],
    'riskyTimes': riskyTimes,
    'suggestions': suggestions,
    'source': source,
    'dailyTotals': dailyTotals,
    'blocks': blocks,
    'sentToTelegramAt': sentToTelegramAt?.toIso8601String(),
    'sample': sample,
  };
}
