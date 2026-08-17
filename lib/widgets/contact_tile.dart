import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_theme.dart';
import 'user_avatar.dart';

/// One row in the Contacts list: avatar, name, mesh ID / status,
/// and an optional trailing action (used by the "Nearby" add flow).
class ContactTile extends StatelessWidget {
  const ContactTile({
    super.key,
    required this.name,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final String name;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppRadii.tile),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.tile),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              UserAvatar(name: name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
