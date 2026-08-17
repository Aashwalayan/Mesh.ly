import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

/// A single chat bubble, aligned left for incoming / right for outgoing.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.isOutgoing,
  });

  final String text;
  final bool isOutgoing;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isOutgoing
              ? AppColors.outgoingBubble
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: isOutgoing
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isOutgoing ? AppColors.textHeading : Colors.white,
                height: 1.4,
              ),
        ),
      ),
    );
  }
}
