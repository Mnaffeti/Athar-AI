/// Answers collected during the onboarding quiz. Used to personalise the plan.
class OnboardingAnswers {
  OnboardingAnswers();

  /// Placeholder profile for returning users until real accounts exist.
  OnboardingAnswers.demo()
    : name = 'Aziz',
      occupation = 'Student',
      goal = 'Stop doomscrolling',
      gymFrequency = '3–4× a week' {
    worstApps = {'Instagram', 'TikTok'};
  }

  String? name;
  double age = 25;
  double heightCm = 175;
  double weightKg = 72;
  String? occupation;
  String? goal;
  double dailyScreenHours = 5;
  Set<String> worstApps = {};
  String? gymFrequency;
  double phoneFreeGoalHours = 3;

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  String get bmiLabel => switch (bmi) {
    < 18.5 => 'Underweight',
    < 25 => 'Healthy',
    < 30 => 'Overweight',
    _ => 'Obese',
  };

  String get initials {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    final letters = parts.where((p) => p.isNotEmpty).take(2).map((p) => p[0]);
    return letters.isEmpty ? '?' : letters.join().toUpperCase();
  }

  /// Screen-time target the plan suggests: cut the current habit by ~40%.
  double get targetScreenHours =>
      (dailyScreenHours * 0.6).clamp(1, 24).roundToDouble();

  /// Hours per year reclaimed if the user hits the target.
  int get hoursReclaimedPerYear =>
      ((dailyScreenHours - targetScreenHours) * 365).round();

  int get weeklyGymGoal => switch (gymFrequency) {
    'Never' => 2,
    '1–2× a week' => 3,
    '3–4× a week' => 4,
    _ => 5,
  };
}
