import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/track_types.dart';
import '../../core/models/song.dart';
import '../../core/providers.dart';
import 'song_detail_screen.dart';

class SongsListScreen extends ConsumerWidget {
  const SongsListScreen({
    super.key,
    required this.choirId,
    required this.voice,
  });

  final String choirId;
  final String voice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(songsRepositoryProvider);
    final appUserAsync = ref.watch(currentAppUserProvider);

    return appUserAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (user) => Scaffold(
        appBar: AppBar(
          backgroundColor: getAppBarColor(user?.voice ?? ''),
          title: Text(user?.role == 'admin_coro' 
              ? 'Todas las Canciones'
              : 'Canciones'
          ),
        ),
        body: StreamBuilder<List<Song>>(
          stream: repo.watchSongsForChoirAndVoice(
            choirId: choirId,
            voice: voice,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final songs = snapshot.data ?? [];
            if (songs.isEmpty) {
              return const Center(
                child: Text('No hay canciones para tu coro/voz'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.music_note,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      song.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: song.tone != null
                        ? Text(
                            'Tono: ${song.tone}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          )
                        : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SongDetailScreen(song: song, voice: voice),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

