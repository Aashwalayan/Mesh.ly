import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_theme.dart';

/// A pill-shaped selectable tab, used for "My QR / Scan QR / Nearby".
class TabChip extends StatelessWidget {
  const TabChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.textPrimary : AppColors.chipInactive,
      borderRadius: BorderRadius.circular(AppRadii.chip),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.chip),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : AppColors.accentTabInactive,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
