import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required ChatMessage this.message}) : typing = false;
  const ChatBubble.typing({super.key}) : message = null, typing = true;

  final ChatMessage? message;
  final bool typing;

  @override
  Widget build(BuildContext context) {
    final fromUser = message?.fromUser ?? false;
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: fromUser ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(fromUser ? 18 : 4),
            bottomRight: Radius.circular(fromUser ? 4 : 18),
          ),
          border: fromUser ? null : Border.all(color: AppColors.border),
        ),
        child: typing
            ? const Text('•••', style: TextStyle(color: AppColors.textMuted))
            : Text(
                message!.text,
                style: TextStyle(
                  height: 1.4,
                  color: fromUser ? AppColors.onAccent : AppColors.textPrimary,
                ),
              ),
      ),
    );
  }
}
