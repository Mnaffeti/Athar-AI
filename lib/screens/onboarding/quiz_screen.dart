import 'package:flutter/material.dart';

import '../../models/onboarding_answers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/option_tile.dart';
import 'plan_screen.dart';

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

  Widget _nameStep() => _QuestionPage(
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

  Widget _bodyStep() => _QuestionPage(
    title: 'A little about you',
    subtitle: 'Helps us tailor your gym goals. Only you can see this.',
    child: Column(
      children: [
        _StepperField(
          label: 'Age',
          value: _answers.age,
          min: 13,
          max: 90,
          unit: 'years',
          onChanged: (v) => setState(() => _answers.age = v),
        ),
        _StepperField(
          label: 'Height',
          value: _answers.heightCm,
          min: 120,
          max: 220,
          unit: 'cm',
          onChanged: (v) => setState(() => _answers.heightCm = v),
        ),
        _StepperField(
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
    return _QuestionPage(
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
    return _QuestionPage(
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

  Widget _screenTimeStep() => _QuestionPage(
    title: 'How many hours a day are you on your phone?',
    subtitle: "Be honest — you can check Settings › Screen Time.",
    child: _SliderAnswer(
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
    return _QuestionPage(
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
    return _QuestionPage(
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

  Widget _phoneFreeStep() => _QuestionPage(
    title: 'How many phone-free hours do you want each day?',
    subtitle: 'Time where your phone is locked away. Start small.',
    child: _SliderAnswer(
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

class _QuestionPage extends StatelessWidget {
  const _QuestionPage({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}

/// Card with a big value, −/+ buttons and a slider for quick changes.
class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  void _step(double delta) => onChanged((value + delta).clamp(min, max));

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        text: value.round().toString(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                        children: [
                          TextSpan(
                            text: '  $unit',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _RoundButton(icon: Icons.remove_rounded, onTap: () => _step(-1)),
              const SizedBox(width: 8),
              _RoundButton(icon: Icons.add_rounded, onTap: () => _step(1)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.surfaceHigh,
              thumbColor: AppColors.textPrimary,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _SliderAnswer extends StatelessWidget {
  const _SliderAnswer({
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.footnote,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final String suffix;
  final String Function(double) footnote;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value.round().toString(),
              style: const TextStyle(
                fontSize: 96,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
                letterSpacing: -4,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              suffix,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.surfaceHigh,
            thumbColor: AppColors.textPrimary,
            overlayColor: AppColors.accent.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          footnote(value),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ],
    );
  }
}
