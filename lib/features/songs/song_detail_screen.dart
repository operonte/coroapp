import 'package:flutter/material.dart';

import '../../core/models/song.dart';

class SongDetailScreen extends StatelessWidget {
  const SongDetailScreen({
    super.key,
    required this.song,
    required this.voice,
  });

  final Song song;
  final String voice;

  @override
  Widget build(BuildContext context) {
    final audioUrl = song.audioUrls[voice];

    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voz: $voice'),
            if (song.tone != null) Text('Tono: ${song.tone}'),
            const SizedBox(height: 16),
            if (audioUrl != null)
              Text('Reproductor de audio pendiente para:\n$audioUrl'),
            const SizedBox(height: 16),
            if (song.lyricsUrl != null)
              Text('Letra (PDF): ${song.lyricsUrl}'),
            const SizedBox(height: 16),
            if (song.demoVideoUrl != null)
              Text('Demo video: ${song.demoVideoUrl}'),
          ],
        ),
      ),
    );
  }
}

