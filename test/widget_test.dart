import 'package:flutter_test/flutter_test.dart';

import 'package:quit/main.dart';
import 'package:quit/models/onboarding_answers.dart';
import 'package:quit/pages/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quit/atoms/profile_avatar.dart';

void main() {
  // Splash checks the session, so Supabase must exist (signed out, no network).
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test',
      authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
    );
  });

  testWidgets('Splash leads to welcome, which starts the quiz', (tester) async {
    await tester.pumpWidget(const AtharApp());
    expect(find.text('For bad habits'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('First, what should we call you?'), findsOneWidget);
  });

  testWidgets('Main shell renders all tabs', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: MainShell(profile: OnboardingAnswers.demo())),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Aziz', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('This week'), findsOneWidget);

    await tester.tap(find.text('Coach'));
    await tester.pumpAndSettle();
    expect(find.text('Athar Coach'), findsOneWidget);
  });

  testWidgets('Header avatar opens the profile', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: MainShell(profile: OnboardingAnswers.demo())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ProfileAvatar));
    await tester.pumpAndSettle();
    expect(find.text('175 cm'), findsOneWidget);
    expect(find.text('Student  ·  25 years'), findsOneWidget);
  });
}
