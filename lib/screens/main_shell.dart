import 'package:flutter/material.dart';

import '../models/onboarding_answers.dart';
import 'coach/coach_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'stats/stats_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.profile});

  final OnboardingAnswers profile;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileScreen(profile: widget.profile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.profile.name ?? 'there';
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            profile: widget.profile,
            onOpenStats: () => setState(() => _index = 1),
            onOpenProfile: _openProfile,
          ),
          const StatsScreen(),
          CoachScreen(name: name),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Coach',
          ),
        ],
      ),
    );
  }
}
