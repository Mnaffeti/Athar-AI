import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// First-time Telegram step: open the bot, share the number, come back.
class BotLinkPanel extends StatelessWidget {
  const BotLinkPanel({super.key, required this.onOpenBot, required this.onRetry});

  final VoidCallback onOpenBot;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'This number isn\'t linked to the Athar bot yet',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Open Telegram, tap Start, then "Share my number". '
            'Come back here and tap Send code again.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onOpenBot, child: const Text('Open Telegram')),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Send code again'),
          ),
        ],
      ),
    );
  }
}
