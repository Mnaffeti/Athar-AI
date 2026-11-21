import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/mock_data.dart';

/// Chat completions against Groq's OpenAI-compatible API.
///
/// The key is injected at build time, never committed:
///   flutter run --dart-define-from-file=env.json
class GroqCoach {
  static const apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const model = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: 'openai/gpt-oss-120b',
  );
  static final endpoint = Uri.parse(
    'https://api.groq.com/openai/v1/chat/completions',
  );

  static bool get isConfigured => apiKey.isNotEmpty;

  /// [history] is the conversation so far as (text, fromUser) pairs,
  /// ending with the user's latest message.
  static Future<String> reply({
    required String name,
    required List<(String, bool)> history,
  }) async {
    final response = await http
        .post(
          endpoint,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'temperature': 0.7,
            // gpt-oss is a reasoning model; reasoning tokens count toward
            // max_tokens, so keep effort low and leave headroom.
            'reasoning_effort': 'low',
            'max_tokens': 1024,
            'messages': [
              {'role': 'system', 'content': _systemPrompt(name)},
              for (final (text, fromUser) in history)
                {'role': fromUser ? 'user' : 'assistant', 'content': text},
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Groq ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return (data['choices'][0]['message']['content'] as String).trim();
  }

  static String _systemPrompt(String name) {
    final metrics = MockData.all
        .map(
          (m) =>
              '- ${m.label}: today ${m.format(m.today)}, '
              'goal ${m.format(m.goal)}, '
              'last 7 days ${m.week.map(m.format).join(', ')}',
        )
        .join('\n');
    return '''
You are the Athar (أثر) coach, a warm, practical habit coach inside an app that
helps $name cut down scrolling and screen time and spend more time at the gym
and phone-free. Keep replies short (2-4 sentences), concrete and encouraging.
Use the user's numbers when relevant. Reply in the language the user writes in.

$name's current stats:
- Streak: ${MockData.streakDays} days
- Total gym hours: ${MockData.totalGymHours}
- Total phone-free hours: ${MockData.totalPhoneFreeHours}
$metrics''';
  }
}
