import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import '../models/message.dart';

/// A single chat bubble, aligned left for incoming / right for outgoing.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.isOutgoing,
    this.deliveryState,
  });

  final String text;
  final bool isOutgoing;
  final MessageDeliveryState? deliveryState;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isOutgoing ? AppColors.textHeading : Colors.white,
                    height: 1.4,
                  ),
            ),
            if (isOutgoing && deliveryState != null) ...[
              const SizedBox(height: 4),
              Text(
                switch (deliveryState!) {
                  MessageDeliveryState.sending => 'Sending',
                  MessageDeliveryState.sent => 'Sent',
                  MessageDeliveryState.received => 'Received',
                },
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
