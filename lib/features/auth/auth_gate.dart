import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../home/home_shell.dart';
import '../profile/profile_setup_screen.dart';
import 'login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final appUserAsync = ref.watch(currentAppUserProvider);

    return authAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error de autenticación: $e')),
      ),
      data: (firebaseUser) {
        if (firebaseUser == null) {
          return const LoginScreen();
        }

        return appUserAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            body: Center(child: Text('Error cargando perfil: $e')),
          ),
          data: (appUser) {
            if (appUser == null || !appUser.hasCompletedProfile) {
              return const ProfileSetupScreen();
            }
            return const HomeShell();
          },
        );
      },
    );
  }
}

