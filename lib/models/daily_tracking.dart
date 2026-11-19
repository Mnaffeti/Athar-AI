class DailyTracking {
  const DailyTracking({
    required this.date,
    required this.screenHours,
    required this.scrollMinutes,
    required this.socialHours,
    required this.gymHours,
    required this.phoneFreeHours,
  });

  final String date;
  final double screenHours;
  final double scrollMinutes;
  final double socialHours;
  final double gymHours;
  final double phoneFreeHours;

  factory DailyTracking.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return DailyTracking(
      date: json['date']?.toString() ??
          json['created_at']?.toString().split('T').first ??
          '',
      screenHours: number(json['screen_hours'] ?? json['screenTime']),
      scrollMinutes: number(json['scroll_minutes'] ?? json['scroll']),
      socialHours: number(json['social_hours'] ?? json['socialMedia']),
      gymHours: number(json['gym_hours'] ?? json['gym']),
      phoneFreeHours:
          number(json['phone_free_hours'] ?? json['phoneFree']),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'screen_hours': screenHours,
        'scroll_minutes': scrollMinutes,
        'social_hours': socialHours,
        'gym_hours': gymHours,
        'phone_free_hours': phoneFreeHours,
      };

  DailyTracking copyWith({
    String? date,
    double? screenHours,
    double? scrollMinutes,
    double? socialHours,
    double? gymHours,
    double? phoneFreeHours,
  }) {
    return DailyTracking(
      date: date ?? this.date,
      screenHours: screenHours ?? this.screenHours,
      scrollMinutes: scrollMinutes ?? this.scrollMinutes,
      socialHours: socialHours ?? this.socialHours,
      gymHours: gymHours ?? this.gymHours,
      phoneFreeHours: phoneFreeHours ?? this.phoneFreeHours,
    );
  }
}
