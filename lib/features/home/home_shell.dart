import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../screens/privacy_policy_screen.dart';
import '../songs/songs_list_screen.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(currentAppUserProvider);

    return appUserAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error cargando usuario: $e')),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Sin usuario')),
          );
        }

        if (!user.hasCompletedProfile) {
          return const Scaffold(
            body: Center(child: Text('Perfil incompleto')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('CoroApp - ${user.voice ?? ''}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.privacy_tip_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SongsListScreen(
            choirId: user.choirId!,
            voice: user.voice!,
          ),
        );
      },
    );
  }
}

