import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/onboarding_answers.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../onboarding/welcome_screen.dart';
import '../../atoms/app_card.dart';
import '../../atoms/profile_avatar.dart';

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
          const _SectionTitle('Body'),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoTile(label: 'Height', value: '${p.heightCm.round()} cm'),
                const SizedBox(width: 10),
                _InfoTile(label: 'Weight', value: '${p.weightKg.round()} kg'),
                const SizedBox(width: 10),
                _InfoTile(
                  label: 'BMI · ${p.bmiLabel}',
                  value: p.bmi.toStringAsFixed(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Lifetime'),
          const IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoTile(
                  label: 'Hours in gym',
                  value: '${MockData.totalGymHours}h',
                  color: AppColors.gym,
                ),
                SizedBox(width: 10),
                _InfoTile(
                  label: 'Hours phone-free',
                  value: '128h',
                  color: AppColors.phoneFree,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('My goals'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _GoalRow(
                  icon: Icons.flag_rounded,
                  label: 'Main goal',
                  value: p.goal ?? '—',
                ),
                _GoalRow(
                  icon: Icons.smartphone_rounded,
                  label: 'Screen time limit',
                  value: '${p.targetScreenHours.round()}h / day',
                ),
                _GoalRow(
                  icon: Icons.do_not_disturb_on_rounded,
                  label: 'Phone-free',
                  value: '${p.phoneFreeGoalHours.round()}h / day',
                ),
                _GoalRow(
                  icon: Icons.fitness_center_rounded,
                  label: 'Gym',
                  value: '${p.weeklyGymGoal}× / week',
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Settings'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  onTap: () => _comingSoon(context),
                ),
                _SettingsRow(
                  icon: Icons.widgets_outlined,
                  label: 'Home-screen widgets',
                  onTap: () => _comingSoon(context),
                ),
                _SettingsRow(
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color ?? AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
