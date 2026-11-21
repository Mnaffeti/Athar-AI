import 'package:flutter/material.dart';

import '../models/app_usage.dart';
import '../theme/app_theme.dart';

/// One tracked habit metric with today's value and the last 7 days.
class Metric {
  const Metric({
    required this.id,
    required this.label,
    required this.unit,
    required this.icon,
    required this.color,
    required this.today,
    required this.goal,
    required this.week,
    required this.lowerIsBetter,
  });

  final String id;
  final String label;
  final String unit;
  final IconData icon;
  final Color color;
  final double today;
  final double goal;
  final List<double> week; // Mon..Sun, last entry is today
  final bool lowerIsBetter;

  double get progress => (today / goal).clamp(0, 1.5);

  bool get onTrack => lowerIsBetter ? today <= goal : today >= goal;

  double get weekTotal => week.fold(0, (a, b) => a + b);

  Metric copyWith({double? today, List<double>? week}) {
    return Metric(
      id: id,
      label: label,
      unit: unit,
      icon: icon,
      color: color,
      today: today ?? this.today,
      goal: goal,
      week: week ?? this.week,
      lowerIsBetter: lowerIsBetter,
    );
  }

  /// Change vs yesterday as a fraction (e.g. -0.12 = 12% less).
  double get deltaVsYesterday {
    final yesterday = week[week.length - 2];
    if (yesterday == 0) return 0;
    return (today - yesterday) / yesterday;
  }

  String format(double v) {
    if (unit == 'h') {
      final h = v.floor();
      final m = ((v - h) * 60).round();
      return h == 0 ? '${m}m' : '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    if (unit == 'm' && v >= 1000) return '${(v / 1000).toStringAsFixed(1)} km';
    return '${v.round()} $unit';
  }
}

/// Demo data until real tracking is wired up.
class MockData {
  static const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  static const streakDays = 12;
  static const totalGymHours = 46.5;
  static const totalPhoneFreeHours = 128.0;

  static const scroll = Metric(
    id: 'scroll',
    label: 'Scrolled',
    unit: 'm',
    icon: Icons.swipe_vertical_rounded,
    color: AppColors.scroll,
    today: 312,
    goal: 400,
    week: [610, 540, 480, 520, 390, 445, 312],
    lowerIsBetter: true,
  );

  static const screenTime = Metric(
    id: 'screen',
    label: 'Screen time',
    unit: 'h',
    icon: Icons.smartphone_rounded,
    color: AppColors.screen,
    today: 3.4,
    goal: 3,
    week: [5.2, 4.8, 4.1, 4.4, 3.6, 3.9, 3.4],
    lowerIsBetter: true,
  );

  static const socialMedia = Metric(
    id: 'social',
    label: 'Social media',
    unit: 'h',
    icon: Icons.forum_rounded,
    color: AppColors.social,
    today: 1.2,
    goal: 1.5,
    week: [2.6, 2.2, 1.9, 2.0, 1.4, 1.7, 1.2],
    lowerIsBetter: true,
  );

  static const gym = Metric(
    id: 'gym',
    label: 'Gym',
    unit: 'h',
    icon: Icons.fitness_center_rounded,
    color: AppColors.gym,
    today: 1.25,
    goal: 1,
    week: [1.0, 0, 1.5, 0, 1.2, 0.75, 1.25],
    lowerIsBetter: false,
  );

  static const phoneFree = Metric(
    id: 'phonefree',
    label: 'Phone-free',
    unit: 'h',
    icon: Icons.do_not_disturb_on_rounded,
    color: AppColors.phoneFree,
    today: 2.6,
    goal: 3,
    week: [1.2, 1.8, 2.0, 2.4, 3.1, 2.2, 2.6],
    lowerIsBetter: false,
  );

  static const all = [screenTime, scroll, socialMedia, gym, phoneFree];

  static const appBreakdown = [
    ('Instagram', 0.55, AppColors.social),
    ('TikTok', 0.4, AppColors.screen),
    ('YouTube', 0.9, AppColors.scroll),
    ('X', 0.25, AppColors.textSecondary),
  ];

  /// 7 days of per-app usage from [appBreakdown], for previewing the report
  /// where real usage can't be read (web, iOS). Evenings are the busiest.
  static List<AppUsageDay> sampleUsage({DateTime? today}) {
    const dayFactor = [1.2, 1.1, 0.9, 1.0, 0.8, 1.4, 1.3]; // Mon..Sun
    const hourShare = {8: 0.1, 13: 0.2, 18: 0.25, 21: 0.45};
    final end = today ?? DateTime.now();
    return [
      for (var back = 6; back >= 0; back--)
        for (final (name, hours, _) in appBreakdown)
          () {
            final day = DateTime(end.year, end.month, end.day - back);
            final minutes = hours * 60 * dayFactor[day.weekday - 1];
            return AppUsageDay(
              date: '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
              package: 'sample.$name',
              label: name,
              minutes: minutes,
              hourly: [for (var h = 0; h < 24; h++) minutes * (hourShare[h] ?? 0)],
            );
          }(),
    ];
  }

  /// Fun comparison for the scroll distance.
  static String scrollComparison(double meters) {
    if (meters >= 828) return 'taller than the Burj Khalifa';
    if (meters >= 330) return 'taller than the Eiffel Tower';
    if (meters >= 93) return 'taller than the Statue of Liberty';
    return 'about ${(meters / 3).round()} floors of a building';
  }
}
