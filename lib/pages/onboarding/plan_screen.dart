import 'package:flutter/material.dart';

import '../../models/onboarding_answers.dart';
import '../../services/auth_service.dart';
import '../auth/sign_in_screen.dart';
import '../main_shell.dart';
import '../../components/analysing_view.dart';
import '../../components/plan_summary.dart';

/// Signed-in users without a profile (new account from Welcome) save it here;
/// everyone else signs in first.
Future<void> _savePlan(BuildContext context, OnboardingAnswers a) async {
  final nav = Navigator.of(context);
  if (!AuthService.isSignedIn) {
    nav.push(MaterialPageRoute(builder: (_) => SignInScreen(answers: a)));
    return;
  }
  try {
    await AuthService.saveProfile(a);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AuthService.errorMessage(e))),
    );
    return;
  }
  nav.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => MainShell(profile: a)),
    (_) => false,
  );
}

/// Shows a short "analysing" state, then reveals the personalised plan.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, required this.answers});

  final OnboardingAnswers answers;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _loading
              ? const AnalysingView(key: ValueKey('loading'))
              : PlanSummary(
                  key: const ValueKey('plan'),
                  answers: widget.answers,
                  onSave: (ctx) => _savePlan(ctx, widget.answers),
                ),
        ),
      ),
    );
  }
}
