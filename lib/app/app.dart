import 'package:flutter/material.dart';

import '../data/identity_repository.dart';
import '../screens/home/home_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import 'theme/app_theme.dart';

/// Root widget: sets up the MaterialApp shell, theme, and the startup gate
/// that decides between onboarding and the home screen.
class MeshlyApp extends StatelessWidget {
  const MeshlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mesh.ly',
      theme: AppTheme.light(),
      home: const AppStartupGate(),
    );
  }
}

/// Waits for [IdentityRepository] to finish reading any saved identity from
/// disk, then shows [OnboardingScreen] (no identity yet) or [HomeScreen]
/// (identity exists) — and keeps listening, so finishing onboarding swaps
/// straight to [HomeScreen] with no separate navigation call needed.
class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  @override
  void initState() {
    super.initState();
    IdentityRepository.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: IdentityRepository.instance,
      builder: (context, _) {
        final identity = IdentityRepository.instance;

        if (!identity.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return identity.hasIdentity
            ? const HomeScreen()
            : const OnboardingScreen();
      },
    );
  }
}