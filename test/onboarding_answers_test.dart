import 'package:flutter_test/flutter_test.dart';
import 'package:quit/models/onboarding_answers.dart';

void main() {
  test('OnboardingAnswers survives a JSON round-trip', () {
    final a = OnboardingAnswers()
      ..name = 'Sara'
      ..age = 31
      ..heightCm = 168
      ..weightKg = 60.5
      ..occupation = 'Engineer'
      ..goal = 'Sleep better'
      ..dailyScreenHours = 7
      ..worstApps = {'TikTok', 'YouTube'}
      ..gymFrequency = '1–2× a week'
      ..phoneFreeGoalHours = 2;

    final b = OnboardingAnswers.fromJson(a.toJson());

    expect(b.toJson(), a.toJson());
    expect(b.worstApps, {'TikTok', 'YouTube'});
  });

  test('fromJson keeps defaults for missing fields', () {
    final b = OnboardingAnswers.fromJson({'name': 'Ali', 'age': 40});
    expect(b.name, 'Ali');
    expect(b.age, 40);
    expect(b.heightCm, 175);
    expect(b.worstApps, isEmpty);
  });
}
