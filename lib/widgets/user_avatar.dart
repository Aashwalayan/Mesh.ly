import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

/// A circular avatar showing a person's initials.
///
/// Later this can grow an `imageUrl`/`avatarAsset` branch without changing
/// any call sites.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.radius = 26,
    this.backgroundColor = AppColors.accentSoft,
    this.textColor = AppColors.accentDark,
  });

  final String name;
  final double radius;
  final Color backgroundColor;
  final Color textColor;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2);
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        _initials,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
