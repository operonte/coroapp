import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/track_types.dart';
import '../../core/providers.dart';
import '../settings/settings_screen.dart';
import '../songs/create_song_screen.dart';
import '../songs/songs_list_screen.dart';
import '../reminders/reminder_screen.dart';

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
            backgroundColor: getAppBarColor(user.voice ?? ''),
            title: Text('CoroApp · ${(user.voice ?? '').toUpperCase()}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Recordatorios',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReminderScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Configuración',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
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
          floatingActionButton: user.role == 'admin_coro'
              ? FloatingActionButton(
                  tooltip: 'Nueva canción',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CreateSongScreen(choirId: user.choirId!),
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }
}

