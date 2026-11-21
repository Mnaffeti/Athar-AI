import 'package:flutter/material.dart';

import '../../models/onboarding_answers.dart';
import '../../theme/app_theme.dart';
import 'plan_screen.dart';
import '../../components/option_tile.dart';
import '../../components/question_page.dart';
import '../../components/slider_answer.dart';
import '../../components/stepper_field.dart';

/// Multi-step onboarding questionnaire, one question per page.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _answers = OnboardingAnswers();
  int _step = 0;

  static const _stepCount = 8;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
    0 => _nameController.text.trim().isNotEmpty,
    2 => _answers.occupation != null,
    3 => _answers.goal != null,
    5 => _answers.worstApps.isNotEmpty,
    6 => _answers.gymFrequency != null,
    _ => true,
  };

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step == _stepCount - 1) {
      _answers.name = _nameController.text.trim();
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => PlanScreen(answers: _answers)));
      return;
    }
    setState(() => _step++);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step--);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: (_step + 1) / _stepCount),
                          duration: const Duration(milliseconds: 350),
                          builder: (context, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceHigh,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_step + 1}/$_stepCount',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _nameStep(),
                    _bodyStep(),
                    _occupationStep(),
                    _goalStep(),
                    _screenTimeStep(),
                    _appsStep(),
                    _gymStep(),
                    _phoneFreeStep(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: FilledButton(
                  onPressed: _canContinue ? _next : null,
                  child: Text(
                    _step == _stepCount - 1 ? 'Build my plan' : 'Continue',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Steps ---------------------------------------------------------------

  Widget _nameStep() => QuestionPage(
    title: "First, what should we call you?",
    subtitle: 'Your coach will use this to keep things personal.',
    child: TextField(
      controller: _nameController,
      autofocus: false,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(fontSize: 18),
      decoration: const InputDecoration(hintText: 'Your first name'),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _canContinue ? _next() : null,
    ),
  );

  Widget _bodyStep() => QuestionPage(
    title: 'A little about you',
    subtitle: 'Helps us tailor your gym goals. Only you can see this.',
    child: Column(
      children: [
        StepperField(
          label: 'Age',
          value: _answers.age,
          min: 13,
          max: 90,
          unit: 'years',
          onChanged: (v) => setState(() => _answers.age = v),
        ),
        StepperField(
          label: 'Height',
          value: _answers.heightCm,
          min: 120,
          max: 220,
          unit: 'cm',
          onChanged: (v) => setState(() => _answers.heightCm = v),
        ),
        StepperField(
          label: 'Weight',
          value: _answers.weightKg,
          min: 30,
          max: 200,
          unit: 'kg',
          onChanged: (v) => setState(() => _answers.weightKg = v),
        ),
      ],
    ),
  );

  Widget _occupationStep() {
    const options = [
      ('🎓', 'Student'),
      ('💼', 'Office / desk job'),
      ('🏠', 'Remote / work from home'),
      ('🎨', 'Creative / freelancer'),
      ('🩺', 'Healthcare'),
      ('🛠️', 'Hands-on / physical work'),
      ('🚀', 'Entrepreneur'),
      ('✨', 'Other'),
    ];
    return QuestionPage(
      title: 'What do you do?',
      subtitle: 'Your day shapes your screen habits.',
      child: Column(
        children: [
          for (final (emoji, label) in options)
            OptionTile(
              emoji: emoji,
              label: label,
              selected: _answers.occupation == label,
              onTap: () => setState(() => _answers.occupation = label),
            ),
        ],
      ),
    );
  }

  Widget _goalStep() {
    const goals = [
      ('🧠', 'Stop doomscrolling'),
      ('📵', 'Cut my screen time'),
      ('💪', 'Be more consistent at the gym'),
      ('🎯', 'Focus better at work / school'),
      ('😴', 'Sleep better'),
    ];
    return QuestionPage(
      title: "What's your main goal?",
      subtitle: 'Pick the one that matters most right now.',
      child: Column(
        children: [
          for (final (emoji, label) in goals)
            OptionTile(
              emoji: emoji,
              label: label,
              selected: _answers.goal == label,
              onTap: () => setState(() => _answers.goal = label),
            ),
        ],
      ),
    );
  }

  Widget _screenTimeStep() => QuestionPage(
    title: 'How many hours a day are you on your phone?',
    subtitle: "Be honest — you can check Settings › Screen Time.",
    child: SliderAnswer(
      value: _answers.dailyScreenHours,
      min: 1,
      max: 12,
      suffix: 'h / day',
      footnote: (v) =>
          "That's ${(v * 365 / 24).round()} full days a year on your phone.",
      onChanged: (v) => setState(() => _answers.dailyScreenHours = v),
    ),
  );

  Widget _appsStep() {
    const apps = [
      ('📸', 'Instagram'),
      ('🎵', 'TikTok'),
      ('▶️', 'YouTube'),
      ('𝕏', 'X / Twitter'),
      ('👻', 'Snapchat'),
      ('🎮', 'Games'),
    ];
    return QuestionPage(
      title: 'Which apps steal most of your time?',
      subtitle: 'Select all that apply.',
      child: Column(
        children: [
          for (final (emoji, label) in apps)
            OptionTile(
              emoji: emoji,
              label: label,
              selected: _answers.worstApps.contains(label),
              onTap: () => setState(() {
                _answers.worstApps.contains(label)
                    ? _answers.worstApps.remove(label)
                    : _answers.worstApps.add(label);
              }),
            ),
        ],
      ),
    );
  }

  Widget _gymStep() {
    const options = [
      ('🛋️', 'Never'),
      ('🚶', '1–2× a week'),
      ('🏃', '3–4× a week'),
      ('🏋️', '5+ times a week'),
    ];
    return QuestionPage(
      title: 'How often do you work out?',
      subtitle: "We'll track your gym time and total hours.",
      child: Column(
        children: [
          for (final (emoji, label) in options)
            OptionTile(
              emoji: emoji,
              label: label,
              selected: _answers.gymFrequency == label,
              onTap: () => setState(() => _answers.gymFrequency = label),
            ),
        ],
      ),
    );
  }

  Widget _phoneFreeStep() => QuestionPage(
    title: 'How many phone-free hours do you want each day?',
    subtitle: 'Time where your phone is locked away. Start small.',
    child: SliderAnswer(
      value: _answers.phoneFreeGoalHours,
      min: 1,
      max: 8,
      suffix: 'h phone-free',
      footnote: (v) => v <= 2
          ? 'A great starting point.'
          : v <= 4
          ? 'Ambitious — we like it.'
          : 'Monk mode. Respect.',
      onChanged: (v) => setState(() => _answers.phoneFreeGoalHours = v),
    ),
  );
}
