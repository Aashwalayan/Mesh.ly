import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../data/identity_repository.dart';

/// Shown once, the first time the app runs on a device: asks for a display
/// name and creates this install's on-device identity (see
/// [IdentityRepository]). No account, no server — just a name and a
/// randomly generated Mesh ID saved locally.
///
/// Doesn't navigate anywhere itself on success — [AppStartupGate] listens
/// to [IdentityRepository] and swaps to [HomeScreen] once an identity
/// exists.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _saving) return;

    setState(() => _saving = true);
    await IdentityRepository.instance.create(name);
    // No further action needed here — AppStartupGate rebuilds into
    // HomeScreen once IdentityRepository.instance.hasIdentity is true.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome to Mesh.ly',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'What should people see when they scan your QR code or '
                'find you nearby? This stays on your phone — nothing is '
                'sent to a server.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(hintText: 'Your name'),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}