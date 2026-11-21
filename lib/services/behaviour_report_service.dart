import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_usage.dart';
import 'groq_coach.dart';
import 'usage_insights.dart';

enum TelegramSendError { notLinked, blocked, failed }

/// AI behaviour report: Groq writes the words, [summarize] provides every number.
class BehaviourReportService {
  BehaviourReportService._();

  static const minDays = 3;
  static const cooldown = Duration(hours: 1);
  static const _reportKey = 'behaviour_report_v1';
  static const _consentKey = 'behaviour_report_consent';

  // shortcut: only these well-known names are checked for invented apps; widen if reports mention others.
  static const _knownApps = [
    'Instagram', 'TikTok', 'YouTube', 'Facebook', 'Snapchat', 'Twitter', 'X',
    'WhatsApp', 'Telegram', 'Reddit', 'Netflix', 'Spotify', 'Chrome',
    'Discord', 'Pinterest', 'LinkedIn', 'Twitch', 'Messenger', 'Threads',
  ];

  /// Groq when possible, the offline summary otherwise (spec FR-007).
  /// [sample] marks a preview built from demo data.
  static Future<BehaviourReport> generate(
    UsageSummary s, {
    String? goal,
    bool sample = false,
  }) async {
    BehaviourReport report;
    try {
      report = validate(await _askGroq(s, goal), s) ?? offlineReport(s);
    } catch (_) {
      report = offlineReport(s);
    }
    if (sample) report = report.asSample();
    await save(report);
    return report;
  }

  static Future<Map<String, dynamic>> _askGroq(UsageSummary s, String? goal) async {
    if (!GroqCoach.isConfigured) throw StateError('no Groq key');
    // Aggregates only: no name, email or phone (spec FR-012).
    final input = {
      'goal': goal ?? 'Use my phone less',
      'days': s.days,
      'daily_minutes': {
        for (final e in s.dailyTotals.entries) weekdayName(e.key): e.value.round(),
      },
      'top_apps': [
        for (final a in s.topApps)
          {'app': a.label, 'min_per_day': a.minPerDay.round(), 'share_pct': a.sharePct.round()},
      ],
      'blocks_min_per_day': {
        for (var i = 0; i < 6; i++) blockLabels[i]: s.blocks[i].round(),
      },
      'weekday_avg': s.weekdayAvg.round(),
      'weekend_avg': s.weekendAvg.round(),
      'change_pct': s.changePct.round(),
      'forecast_week_minutes': {
        for (final p in s.forecast)
          p.subject: {'mean': p.mean.round(), 'low': p.low.round(), 'high': p.high.round()},
      },
    };
    final response = await http
        .post(
          GroqCoach.endpoint,
          headers: {
            'Authorization': 'Bearer ${GroqCoach.apiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': GroqCoach.model,
            'temperature': 0.4,
            'reasoning_effort': 'low',
            'max_tokens': 1500,
            'response_format': {'type': 'json_object'},
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {'role': 'user', 'content': jsonEncode(input)},
            ],
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Groq ${response.statusCode}');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final content = data['choices'][0]['message']['content'] as String;
    return Map<String, dynamic>.from(jsonDecode(content) as Map);
  }

  static const _systemPrompt = '''
You analyse a user's phone screen time for the Athar app and reply with JSON only.
Use ONLY the numbers and app names in the input. Never invent apps, numbers or dates.
Reply with exactly these keys:
{"patterns": [2 to 4 short sentences, each citing a number from the input],
 "prediction_notes": {"<subject from forecast_week_minutes>": "one short sentence"},
 "risky_times": [1 or 2 items like "20:00–24:00: 98 min/day, mostly Instagram"],
 "suggestions": [exactly 3 concrete, kind suggestions tied to the goal]}
Minutes can be written as hours and minutes. Keep each item under 30 words.''';

  /// Checks the model's reply; null means "use the offline report".
  /// Numbers always come from [s.forecast], never from the reply (spec FR-006).
  static BehaviourReport? validate(Map<String, dynamic> reply, UsageSummary s, {DateTime? now}) {
    List<String>? strings(String key) {
      final v = reply[key];
      return v is List ? [for (final x in v) if (x is String && x.trim().isNotEmpty) x.trim()] : null;
    }

    bool real(String text) => !_knownApps.any(
      (app) => !s.appNames.contains(app) && RegExp('\\b${RegExp.escape(app)}\\b').hasMatch(text),
    );

    final patterns = strings('patterns')?.where(real).take(4).toList();
    final risky = strings('risky_times')?.where(real).take(2).toList();
    final suggestions = strings('suggestions')?.where(real).toList();
    final notes = reply['prediction_notes'];
    if (patterns == null || patterns.length < 2) return null;
    if (risky == null || risky.isEmpty) return null;
    if (suggestions == null || suggestions.length < 3) return null;

    return BehaviourReport(
      generatedAt: now ?? DateTime.now(),
      periodStart: s.periodStart,
      periodEnd: s.periodEnd,
      patterns: patterns,
      predictions: [
        for (final p in s.forecast)
          p.withNote(notes is Map && notes[p.subject] is String ? notes[p.subject] as String : null),
      ],
      riskyTimes: risky,
      suggestions: suggestions.take(3).toList(),
      source: 'ai',
      dailyTotals: s.dailyTotals,
      blocks: s.blocks,
    );
  }

  static Future<BehaviourReport?> loadLatest() async {
    final raw = (await SharedPreferences.getInstance()).getString(_reportKey);
    if (raw == null) return null;
    try {
      return BehaviourReport.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null; // old or corrupt entry: behave as if there is none
    }
  }

  static Future<void> save(BehaviourReport r) async =>
      (await SharedPreferences.getInstance()).setString(_reportKey, jsonEncode(r.toJson()));

  /// Time until a new report may be generated (spec FR-009).
  static Duration cooldownLeft(BehaviourReport? latest, {DateTime? now}) {
    if (latest == null) return Duration.zero;
    final left = cooldown - (now ?? DateTime.now()).difference(latest.generatedAt);
    return left.isNegative ? Duration.zero : left;
  }

  static Future<bool> hasConsent() async =>
      (await SharedPreferences.getInstance()).getBool(_consentKey) ?? false;

  static Future<void> giveConsent() async =>
      (await SharedPreferences.getInstance()).setBool(_consentKey, true);

  /// Only accounts that signed in with Telegram (spec FR-010, FR-013).
  static bool get canSendToTelegram =>
      (Supabase.instance.client.auth.currentUser?.phone ?? '').isNotEmpty;

  /// Sends through the `send-report-telegram` Edge Function; null on success.
  static Future<TelegramSendError?> sendToTelegram(BehaviourReport r, Uint8List? chartPng) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'send-report-telegram',
        body: {
          'text': asText(r),
          if (chartPng != null) 'chartPngBase64': base64Encode(chartPng),
        },
      );
    } on FunctionException catch (e) {
      final code = e.details is Map ? (e.details as Map)['error'] : null;
      return switch (code) {
        'telegram_not_linked' => TelegramSendError.notLinked,
        'telegram_blocked' => TelegramSendError.blocked,
        _ => TelegramSendError.failed,
      };
    } catch (_) {
      return TelegramSendError.failed;
    }
    await save(r.markSent(DateTime.now()));
    return null;
  }

  /// Plain-text version for Telegram (≤ 4000 chars).
  static String asText(BehaviourReport r) {
    String hours(double m) => '${(m / 60).toStringAsFixed(m < 600 ? 1 : 0)}h';
    final b = StringBuffer()
      ..writeln('📊 Your Athar report (${r.periodStart} → ${r.periodEnd})')
      ..writeln(r.sample ? '(sample data)' : '')
      ..writeln(r.isOffline ? '(offline summary)\n' : '')
      ..writeln('Patterns');
    for (final p in r.patterns) {
      b.writeln('• $p');
    }
    b.writeln('\nNext week');
    for (final p in r.predictions) {
      b.writeln('• ${p.subject}: ~${hours(p.mean)} (${hours(p.low)}–${hours(p.high)})'
          '${p.note == null ? '' : ' — ${p.note}'}');
    }
    b.writeln('\nRisky times');
    for (final t in r.riskyTimes) {
      b.writeln('• $t');
    }
    b.writeln('\nTry this');
    for (final s in r.suggestions) {
      b.writeln('• $s');
    }
    final text = b.toString().trim();
    return text.length <= 4000 ? text : '${text.substring(0, 3997)}...';
  }
}
