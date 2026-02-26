import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return StreamBuilder<List<Song>>(
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
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return ListTile(
              title: Text(song.title),
              subtitle: Text(song.tone ?? ''),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SongDetailScreen(song: song, voice: voice),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

