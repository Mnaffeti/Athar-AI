import 'dart:async';

import 'package:flutter/material.dart';

import '../models/onboarding_answers.dart';
import '../models/daily_tracking.dart';
import '../data/mock_data.dart';
import '../services/tracking_service.dart';
import '../services/device_usage_service.dart';
import 'coach/coach_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'stats/stats_screen.dart';
import 'tracking/tracking_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.profile});

  final OnboardingAnswers profile;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;
  Timer? _trackingTimer;
  DailyTracking _tracking = DailyTracking(
    date: '',
    screenHours: MockData.screenTime.today,
    scrollMinutes: MockData.scroll.today,
    socialHours: MockData.socialMedia.today,
    gymHours: MockData.gym.today,
    phoneFreeHours: MockData.phoneFree.today,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    await _loadTracking();
    await _importDeviceUsage();
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _importDeviceUsage(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _importDeviceUsage();
    }
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<String?> _importDeviceUsage() async {
    if (!await DeviceUsageService.hasUsageAccess()) {
      return 'Permission required: tap “Open phone settings”.';
    }
    try {
      final entry = await DeviceUsageService.readToday(_tracking);
      if (entry == null) return 'Automatic phone tracking is unavailable.';
      if (!mounted) return null;
      setState(() => _tracking = entry);
      await _submitTracking(entry);
      return null;
    } catch (error) {
      return 'Phone data could not be read: $error';
    }
  }

  Future<void> _loadTracking() async {
    try {
      final entry = await TrackingService.fetchToday();
      if (entry != null && mounted) {
        setState(() => _tracking = entry);
      }
    } catch (_) {
      // Keep the demo values when the configured API is unavailable.
    }
  }

  Future<String?> _submitTracking(DailyTracking entry) async {
    try {
      final saved = await TrackingService.submit(entry);
      if (mounted) setState(() => _tracking = saved);
      return TrackingService.isConfigured ? null : null;
    } catch (error) {
      return 'Save failed: $error';
    }
  }

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
            tracking: _tracking,
            onOpenStats: () => setState(() => _index = 1),
            onOpenProfile: _openProfile,
          ),
          StatsScreen(tracking: _tracking, goal: widget.profile.goal),
          TrackingScreen(
            key: ValueKey(
              '${_tracking.date}-${_tracking.screenHours}-${_tracking.socialHours}',
            ),
            initialValue: _tracking,
            onSubmit: _submitTracking,
            onImportDeviceUsage: _importDeviceUsage,
            onOpenUsageSettings: DeviceUsageService.openUsageAccessSettings,
          ),
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
            icon: Icon(Icons.edit_calendar_outlined),
            selectedIcon: Icon(Icons.edit_calendar),
            label: 'Track',
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
