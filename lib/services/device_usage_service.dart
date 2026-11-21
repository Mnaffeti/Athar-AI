import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../models/app_usage.dart';
import '../models/daily_tracking.dart';

class DeviceUsageService {
  static const _channel = MethodChannel('athar/device_usage');

  static Future<bool> hasUsageAccess() async {
    if (kIsWeb) return false;
    try {
      return await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> openUsageAccessSettings() async {
    if (kIsWeb) return;
    await _channel.invokeMethod<void>('openUsageAccessSettings');
  }

  /// Per-app usage for the last [days] local days, or null when unavailable
  /// (web/iOS, or usage access not granted).
  static Future<List<AppUsageDay>?> readAppUsage({int days = 7}) async {
    if (kIsWeb) return null;
    try {
      final rows = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'getAppUsage',
        {'days': days},
      );
      return rows?.map(AppUsageDay.fromMap).toList();
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static Future<DailyTracking?> readToday(DailyTracking current) async {
    if (kIsWeb) return null;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getTodayUsage',
      );
      if (result == null) return null;
      return current.copyWith(
        date: result['date']?.toString(),
        screenHours: (result['screen_hours'] as num?)?.toDouble(),
        socialHours: (result['social_hours'] as num?)?.toDouble(),
        scrollMinutes: (result['scroll_minutes'] as num?)?.toDouble(),
      );
    } on MissingPluginException {
      return null;
    }
  }
}
