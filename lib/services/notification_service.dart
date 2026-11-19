import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/daily_tracking.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const _reminderEnabledKey = 'daily_tracking_reminder';
  static const _reminderHourKey = 'daily_tracking_reminder_hour';
  static const _reminderMinuteKey = 'daily_tracking_reminder_minute';

  static Future<void> initialize() async {
    if (kIsWeb) return;
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _notifications.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
    );
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  static Future<bool> isReminderEnabled() async {
    if (kIsWeb) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderEnabledKey) ?? true;
  }

  static Future<Duration> getReminderTime() async {
    if (kIsWeb) return const Duration(hours: 20);
    final prefs = await SharedPreferences.getInstance();
    return Duration(
      hours: prefs.getInt(_reminderHourKey) ?? 20,
      minutes: prefs.getInt(_reminderMinuteKey) ?? 0,
    );
  }

  static Future<void> setDailyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, enabled);
    await prefs.setInt(_reminderHourKey, hour);
    await prefs.setInt(_reminderMinuteKey, minute);

    if (!enabled) {
      await _notifications.cancel(id: 100);
      return;
    }

    await _notifications.zonedSchedule(
      id: 100,
      title: 'Athar daily tracking',
      body: 'Take a minute to record today’s screen and habit data.',
      scheduledDate: _nextReminder(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_tracking',
          'Daily tracking',
          channelDescription: 'Daily Athar tracking reminder',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextReminder(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> showGoalAlert(DailyTracking entry) async {
    if (kIsWeb) return;
    final exceeded = <String>[];
    if (entry.screenHours > 3) {
      exceeded.add('screen time (${entry.screenHours.toStringAsFixed(1)}h)');
    }
    if (entry.scrollMinutes > 400) {
      exceeded.add('scrolling (${entry.scrollMinutes.round()}m)');
    }
    if (entry.socialHours > 1.5) {
      exceeded.add('social media (${entry.socialHours.toStringAsFixed(1)}h)');
    }

    if (exceeded.isEmpty) return;
    await _notifications.show(
      id: 101,
      title: 'Athar goal alert',
      body: 'Today you exceeded: ${exceeded.join(', ')}.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_alerts',
          'Goal alerts',
          channelDescription: 'Notifications when daily goals are exceeded',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
