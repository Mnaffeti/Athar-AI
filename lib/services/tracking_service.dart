import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/daily_tracking.dart';

class TrackingService {
  static const _baseUrl = String.fromEnvironment('TRACKING_API_URL');
  static const _apiKey = String.fromEnvironment('TRACKING_API_KEY');

  static bool get isConfigured => _baseUrl.isNotEmpty;

  static Future<DailyTracking?> fetchToday() async {
    if (!isConfigured) return null;

    final today = DateTime.now().toIso8601String().split('T').first;
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {'date': today},
    );
    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Tracking API ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is Map<String, dynamic>) {
      final payload = data['tracking'] ?? data['data'] ?? data;
      if (payload is List && payload.isNotEmpty) {
        return DailyTracking.fromJson(
          Map<String, dynamic>.from(payload.first),
        );
      }
      if (payload is Map) {
        return DailyTracking.fromJson(Map<String, dynamic>.from(payload));
      }
    }
    return null;
  }

  static Future<DailyTracking> submit(DailyTracking entry) async {
    if (!isConfigured) return entry;

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: _headers,
          body: jsonEncode(entry.toJson()),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Tracking API ${response.statusCode}: ${response.body}');
    }

    if (response.body.isEmpty) return entry;
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is Map<String, dynamic>) {
      final payload = data['tracking'] ?? data['data'] ?? data;
      if (payload is Map) {
        return DailyTracking.fromJson(Map<String, dynamic>.from(payload));
      }
    }
    return entry;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey',
      };
}
