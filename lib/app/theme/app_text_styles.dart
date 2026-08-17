import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Small set of text style helpers layered on top of [ThemeData.textTheme].
///
/// Most widgets should keep using `Theme.of(context).textTheme` directly —
/// these helpers only exist for the handful of styles that repeat across
/// screens with the same custom color/weight combo.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle screenTitle(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall!.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.textHeading,
        );
  }

  static TextStyle tileTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        );
  }

  static TextStyle tileSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: AppColors.textSecondary,
        );
  }

  static TextStyle caption(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: AppColors.textMuted,
        );
  }
}
