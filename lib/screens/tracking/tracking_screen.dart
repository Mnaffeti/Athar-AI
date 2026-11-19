import 'package:flutter/material.dart';

import '../../models/daily_tracking.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../services/notification_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({
    super.key,
    required this.initialValue,
    required this.onSubmit,
    required this.onImportDeviceUsage,
    required this.onOpenUsageSettings,
  });

  final DailyTracking initialValue;
  final Future<String?> Function(DailyTracking entry) onSubmit;
  final Future<String?> Function() onImportDeviceUsage;
  final Future<void> Function() onOpenUsageSettings;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late final TextEditingController _screen;
  late final TextEditingController _scroll;
  late final TextEditingController _social;
  late final TextEditingController _gym;
  late final TextEditingController _phoneFree;
  bool _saving = false;
  bool _dailyReminder = true;
  bool _importing = false;
  int _reminderHour = 20;
  int _reminderMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadReminder();
    _screen = TextEditingController(
      text: widget.initialValue.screenHours.toStringAsFixed(1),
    );
    _scroll = TextEditingController(
      text: widget.initialValue.scrollMinutes.round().toString(),
    );
    _social = TextEditingController(
      text: widget.initialValue.socialHours.toStringAsFixed(1),
    );
    _gym = TextEditingController(
      text: widget.initialValue.gymHours.toStringAsFixed(2),
    );
    _phoneFree = TextEditingController(
      text: widget.initialValue.phoneFreeHours.toStringAsFixed(1),
    );
  }

  Future<void> _loadReminder() async {
    final enabled = await NotificationService.isReminderEnabled();
    final time = await NotificationService.getReminderTime();
    if (!mounted) return;
    setState(() {
      _dailyReminder = enabled;
      _reminderHour = time.inHours;
      _reminderMinute = time.inMinutes.remainder(60);
    });
  }

  @override
  void dispose() {
    _screen.dispose();
    _scroll.dispose();
    _social.dispose();
    _gym.dispose();
    _phoneFree.dispose();
    super.dispose();
  }

  double _value(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    setState(() => _saving = true);
    final today = DateTime.now().toIso8601String().split('T').first;
    final entry = DailyTracking(
      date: today,
      screenHours: _value(_screen),
      scrollMinutes: _value(_scroll),
      socialHours: _value(_social),
      gymHours: _value(_gym),
      phoneFreeHours: _value(_phoneFree),
    );
    String? error;
    try {
      error = await widget.onSubmit(entry);
      if (mounted) setState(() => _saving = false);
      if (error == null) {
        await NotificationService.showGoalAlert(entry);
      }
    } catch (notificationError) {
      error ??= 'Tracking saved, but the alert could not be shown';
    } finally {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Daily tracking saved'),
            backgroundColor: error == null
                ? AppColors.surfaceHigh
                : AppColors.brandRed,
          ),
        );
      }
    }
  }

  Future<void> _importDeviceUsage() async {
    setState(() => _importing = true);
    final message = await widget.onImportDeviceUsage();
    if (!mounted) return;
    setState(() => _importing = false);
    if (message == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Phone usage imported')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: message.startsWith('Permission')
            ? SnackBarAction(
                label: 'SETTINGS',
                onPressed: widget.onOpenUsageSettings,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const Text(
            'Daily tracking',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add today’s device and habit data',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _importing ? null : _importDeviceUsage,
            icon: _importing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.smartphone_rounded),
            label: Text(_importing ? 'Reading phone...' : 'Import from phone'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Android permission is required. Screen and social-media time are imported automatically; scroll is an estimate.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _NumberField(
                  controller: _screen,
                  label: 'Screen time',
                  suffix: 'hours',
                  icon: Icons.smartphone_rounded,
                ),
                const SizedBox(height: 12),
                _NumberField(
                  controller: _scroll,
                  label: 'Social scroll',
                  suffix: 'minutes',
                  icon: Icons.swipe_vertical_rounded,
                ),
                const SizedBox(height: 12),
                _NumberField(
                  controller: _social,
                  label: 'Social media',
                  suffix: 'hours',
                  icon: Icons.forum_rounded,
                ),
                const SizedBox(height: 12),
                _NumberField(
                  controller: _gym,
                  label: 'Gym',
                  suffix: 'hours',
                  icon: Icons.fitness_center_rounded,
                ),
                const SizedBox(height: 12),
                _NumberField(
                  controller: _phoneFree,
                  label: 'Phone-free',
                  suffix: 'hours',
                  icon: Icons.do_not_disturb_on_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () async {
              final selected = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: _reminderHour,
                  minute: _reminderMinute,
                ),
              );
              if (selected == null) return;
              await NotificationService.setDailyReminder(
                enabled: _dailyReminder,
                hour: selected.hour,
                minute: selected.minute,
              );
              if (!mounted) return;
              setState(() {
                _reminderHour = selected.hour;
                _reminderMinute = selected.minute;
              });
            },
            icon: const Icon(Icons.schedule_rounded),
            label: const Text('Change reminder time'),
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              value: _dailyReminder,
              onChanged: (value) async {
                final messenger = ScaffoldMessenger.of(context);
                setState(() => _dailyReminder = value);
                if (value) {
                  final granted = await NotificationService.requestPermission();
                  if (!mounted) return;
                  if (!granted) {
                    setState(() => _dailyReminder = false);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Notification permission was denied'),
                      ),
                    );
                    return;
                  }
                }
                await NotificationService.setDailyReminder(
                  enabled: value,
                  hour: _reminderHour,
                  minute: _reminderMinute,
                );
              },
              secondary: const Icon(Icons.notifications_active_outlined),
              title: const Text('Daily reminder'),
              subtitle: Text(
                'Today at ${TimeOfDay(hour: _reminderHour, minute: _reminderMinute).format(context)}',
              ),
              activeThumbColor: AppColors.accent,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(_saving ? 'Saving...' : 'Save today'),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        suffixText: suffix,
      ),
    );
  }
}
