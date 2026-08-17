import 'package:flutter/material.dart';

/// Centralized Mesh.ly color palette.
///
/// Every hardcoded color from the original prototype now lives here so the
/// rest of the app never repeats a raw `Color(0xFF...)` value.
class AppColors {
  AppColors._();

  // Brand
  static const seed = Color(0xFF1B9C85);

  // Surfaces
  static const background = Color(0xFFF3F7F6);
  static const surface = Colors.white;
  static const surfaceMuted = Color(0xFFF2F5F5);
  static const surfaceSelected = Color(0xFFE6F7F3);
  static const surfaceSoft = Color(0xFFF6FAF9);
  static const divider = Color(0xFFDDE8E6);

  // Text
  static const textPrimary = Color(0xFF173935);
  static const textHeading = Color(0xFF123B37);
  static const textSecondary = Color(0xFF6B7C7A);
  static const textMuted = Color(0xFF82918F);
  static const textFaded = Color(0xFF69807B);

  // Accent / interactive
  static const accent = Color(0xFF1B9C85);
  static const accentDark = Color(0xFF0E6B5A);
  static const accentSoft = Color(0xFFDDF5EF);
  static const accentTabInactive = Color(0xFF56716C);
  static const chipInactive = Color(0xFFF1F5F4);

  // Conversation panel (dark gradient)
  static const conversationTop = Color(0xFF123B37);
  static const conversationBottom = Color(0xFF1B5D55);
  static const outgoingBubble = Color(0xFF8EE0CD);

  // Misc
  static const unreadBadge = Color(0xFF1B9C85);
  static const shadow = Color(0x120F172A);
}
