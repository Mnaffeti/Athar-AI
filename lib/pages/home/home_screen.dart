import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/daily_tracking.dart';
import '../../models/onboarding_answers.dart';
import '../../theme/app_theme.dart';
import '../../components/metric_tile.dart';
import '../../components/home_header.dart';
import '../../components/phone_free_card.dart';
import '../../components/screen_time_hero.dart';
import '../../components/scroll_card.dart';
import '../../components/totals_row.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.profile,
    required this.tracking,
    required this.onOpenStats,
    required this.onOpenProfile,
  });

  final OnboardingAnswers profile;
  final DailyTracking tracking;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          HomeHeader(profile: profile, onOpenProfile: onOpenProfile),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 18),
          ScreenTimeHero(tracking: tracking),
          const SizedBox(height: 14),
          ScrollCard(tracking: tracking),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MetricTile(
                  metric: MockData.socialMedia.copyWith(today: tracking.socialHours),
                  onTap: onOpenStats,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: MetricTile(
                  metric: MockData.gym.copyWith(today: tracking.gymHours),
                  onTap: onOpenStats,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TotalsRow(tracking: tracking),
          const SizedBox(height: 14),
          PhoneFreeCard(tracking: tracking),
        ],
      ),
    );
  }
}
