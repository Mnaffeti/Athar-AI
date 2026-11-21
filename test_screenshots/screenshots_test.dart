// Renders every screen of the app to PNG files in /screenshots.
//
// Run:  flutter test --update-goldens test_screenshots
//
// Kept outside /test so the normal `flutter test` run doesn't compare goldens.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quit/models/onboarding_answers.dart';
import 'package:quit/screens/main_shell.dart';
import 'package:quit/screens/splash_screen.dart';
import 'package:quit/theme/app_theme.dart';
import 'package:quit/widgets/profile_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Device {
  const Device(this.name, this.width, this.height, this.pixelRatio);

  final String name;
  final double width; // logical pixels
  final double height;
  final double pixelRatio;
}

const devices = [
  Device('small_phone', 360, 780, 3),
  Device('large_phone', 430, 932, 3),
];

const emojiFamily = 'ScreenshotEmoji';

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> assets) async {
    final loader = FontLoader(name);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
  }

  ByteData file(String path) =>
      ByteData.sublistView(File(path).readAsBytesSync());

  await family('Manrope', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'])
      'assets/fonts/Manrope-$w.ttf',
  ]);
  await family('PlayfairDisplay', [
    for (final w in ['SemiBold', 'Bold', 'ExtraBold'])
      'assets/fonts/PlayfairDisplay-$w.ttf',
  ]);

  // Material icons ship with the Flutter SDK, not the app bundle.
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          file(
            '$flutterRoot/bin/cache/artifacts/material_fonts/'
            'materialicons-regular.otf',
          ),
        ),
      );
    await icons.load();
  }

  // Emoji glyphs (quiz answers, streak) come from the host OS font.
  const windowsEmoji = r'C:\Windows\Fonts\seguiemj.ttf';
  if (File(windowsEmoji).existsSync()) {
    final emoji = FontLoader(emojiFamily)
      ..addFont(Future.value(file(windowsEmoji)));
    await emoji.load();
  }
}

ThemeData _screenshotTheme() {
  final theme = AppTheme.dark;
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamilyFallback: const [emojiFamily]),
  );
}

void main() {
  setUpAll(() async {
    await _loadFonts();
    // Splash checks the session: a signed-out client with no network.
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test',
      authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
    );
  });

  for (final device in devices) {
    testWidgets('screenshots on ${device.name}', (tester) async {
      var index = 0;

      void setHeight(double height) {
        tester.view.physicalSize = Size(
          device.width * device.pixelRatio,
          height * device.pixelRatio,
        );
      }

      tester.view.devicePixelRatio = device.pixelRatio;
      setHeight(device.height);
      addTearDown(tester.view.reset);

      /// The main vertical scroll view of the visible screen, if any.
      ScrollableState? mainScrollable() {
        final finder = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        );
        if (finder.evaluate().isEmpty) return null;
        return tester.state<ScrollableState>(finder.first);
      }

      Future<void> scrollToTop() async {
        final scrollable = mainScrollable();
        if (scrollable == null || !scrollable.position.hasPixels) return;
        scrollable.position.jumpTo(0);
        await tester.pumpAndSettle();
      }

      Future<void> shot(String name) async {
        await scrollToTop();
        index++;
        final file = '${index.toString().padLeft(2, '0')}_$name.png';
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../screenshots/${device.name}/$file'),
        );
      }

      /// Captures a long screen on a canvas tall enough to show all of it,
      /// then restores the normal size.
      Future<void> fullPageShot(String name) async {
        await scrollToTop();
        final extra = mainScrollable()?.position.maxScrollExtent ?? 0;
        if (extra <= 0) return; // Already fits on one screen.
        setHeight(device.height + extra);
        await tester.pumpAndSettle();
        await shot('${name}_full');
        setHeight(device.height);
        await tester.pumpAndSettle();
      }

      Future<void> tapText(String text) async {
        await tester.ensureVisible(find.text(text).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text(text).first);
        await tester.pumpAndSettle();
      }

      // --- Splash & welcome ------------------------------------------------
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _screenshotTheme(),
          home: const SplashScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1600));
      await shot('splash');
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await shot('welcome');

      // --- Onboarding quiz -------------------------------------------------
      await tapText('Get started');
      await tester.enterText(find.byType(TextField), 'Aziz');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await shot('quiz_name');

      await tapText('Continue');
      await shot('quiz_about_you');

      await tapText('Continue');
      await tapText('Student');
      await shot('quiz_occupation');

      await tapText('Continue');
      await tapText('Stop doomscrolling');
      await shot('quiz_goal');

      await tapText('Continue');
      await shot('quiz_screen_time');

      await tapText('Continue');
      await tapText('Instagram');
      await tapText('TikTok');
      await shot('quiz_apps');

      await tapText('Continue');
      await tapText('3–4× a week');
      await shot('quiz_gym');

      await tapText('Continue');
      await shot('quiz_phone_free');

      // --- Plan & sign-up --------------------------------------------------
      await tapText('Build my plan');
      await tester.pump(const Duration(milliseconds: 500));
      await shot('plan_loading');
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await shot('plan');

      await tapText('Save my plan');
      await shot('sign_up');

      // Real sign-in needs an emailed or Telegram code, so enter the app directly.
      Navigator.of(tester.element(find.byType(Scaffold).last)).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainShell(profile: OnboardingAnswers.demo())),
        (_) => false,
      );
      await tester.pumpAndSettle();

      // --- Main app --------------------------------------------------------
      await shot('home');
      await fullPageShot('home');

      await tapText('Stats');
      await shot('stats');
      await fullPageShot('stats');

      await tapText('Coach');
      await shot('coach');
      await tapText('Motivate me for the gym');
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await shot('coach_chat');

      await tapText('Home');
      await tester.tap(find.byType(ProfileAvatar));
      await tester.pumpAndSettle();
      await shot('profile');
      await fullPageShot('profile');
    });
  }
}
