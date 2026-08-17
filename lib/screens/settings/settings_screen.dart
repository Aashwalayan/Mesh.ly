import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../widgets/section_header.dart';

/// Placeholder settings screen. Every item is inert for now — this is just
/// the scaffolding future functionality (theme switching, notification
/// prefs, privacy controls) will attach to.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SectionHeader(label: 'Appearance'),
          _SettingsTile(icon: Icons.palette_outlined, title: 'Theme'),
          _SettingsTile(icon: Icons.text_fields_rounded, title: 'Text size'),
          const SectionHeader(label: 'Notifications'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Message alerts',
          ),
          _SettingsTile(icon: Icons.volume_up_outlined, title: 'Sound'),
          const SectionHeader(label: 'Privacy'),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: 'Mesh identity & keys',
          ),
          _SettingsTile(
            icon: Icons.visibility_outlined,
            title: 'Who can find me nearby',
          ),
          const SectionHeader(label: 'About Mesh.ly'),
          _SettingsTile(icon: Icons.info_outline_rounded, title: 'Version'),
          _SettingsTile(
            icon: Icons.groups_outlined,
            title: 'Project & contributors',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.accentDark),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
      ),
      // TODO: hook up real navigation once each section is implemented.
      onTap: () {},
    );
  }
}
