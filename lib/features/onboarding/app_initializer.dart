import 'package:flutter/material.dart';

import 'onboarding_screen.dart';
import '../auth/auth_gate.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool? _seenOnboarding;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final seen = await hasSeenOnboarding();
    if (mounted) {
      setState(() => _seenOnboarding = seen);
    }
  }

  void _onOnboardingComplete() {
    setState(() => _seenOnboarding = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_seenOnboarding == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_seenOnboarding == false) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }
    return const AuthGate();
  }
}
