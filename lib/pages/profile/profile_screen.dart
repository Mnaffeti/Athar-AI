import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/onboarding_answers.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../onboarding/welcome_screen.dart';
import '../../atoms/app_card.dart';
import '../../atoms/profile_avatar.dart';
import '../../atoms/section_title.dart';
import '../../components/goal_row.dart';
import '../../components/info_tile.dart';
import '../../components/settings_row.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.profile});

  final OnboardingAnswers profile;

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text("You'll need a new code to sign back in."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AuthService.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: () => _comingSoon(context),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(child: ProfileAvatar(initials: p.initials, size: 92)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              p.name ?? 'You',
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              [
                if (p.occupation != null) p.occupation!,
                '${p.age.round()} years',
              ].join('  ·  '),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                '🔥  ${MockData.streakDays}-day streak',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const SectionTitle('Body'),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InfoTile(label: 'Height', value: '${p.heightCm.round()} cm'),
                const SizedBox(width: 10),
                InfoTile(label: 'Weight', value: '${p.weightKg.round()} kg'),
                const SizedBox(width: 10),
                InfoTile(
                  label: 'BMI · ${p.bmiLabel}',
                  value: p.bmi.toStringAsFixed(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Lifetime'),
          const IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InfoTile(
                  label: 'Hours in gym',
                  value: '${MockData.totalGymHours}h',
                  color: AppColors.gym,
                ),
                SizedBox(width: 10),
                InfoTile(
                  label: 'Hours phone-free',
                  value: '128h',
                  color: AppColors.phoneFree,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('My goals'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                GoalRow(
                  icon: Icons.flag_rounded,
                  label: 'Main goal',
                  value: p.goal ?? '—',
                ),
                GoalRow(
                  icon: Icons.smartphone_rounded,
                  label: 'Screen time limit',
                  value: '${p.targetScreenHours.round()}h / day',
                ),
                GoalRow(
                  icon: Icons.do_not_disturb_on_rounded,
                  label: 'Phone-free',
                  value: '${p.phoneFreeGoalHours.round()}h / day',
                ),
                GoalRow(
                  icon: Icons.fitness_center_rounded,
                  label: 'Gym',
                  value: '${p.weeklyGymGoal}× / week',
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Settings'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SettingsRow(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  onTap: () => _comingSoon(context),
                ),
                SettingsRow(
                  icon: Icons.widgets_outlined,
                  label: 'Home-screen widgets',
                  onTap: () => _comingSoon(context),
                ),
                SettingsRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'Privacy',
                  onTap: () => _comingSoon(context),
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => _signOut(context),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.screen),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
