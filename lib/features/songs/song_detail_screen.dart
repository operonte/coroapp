import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/song.dart';
import '../../core/services/storage_url_service.dart';

class SongDetailScreen extends StatefulWidget {
  const SongDetailScreen({
    super.key,
    required this.song,
    required this.voice,
  });

  final Song song;
  final String voice;

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  late final AudioPlayer _player;
  bool _loading = true;
  String? _error;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    final gsUrl = widget.song.audioUrls[widget.voice];
    if (gsUrl == null) {
      setState(() {
        _error = 'No hay audio configurado para esta voz.';
        _loading = false;
      });
      return;
    }

    try {
      final url = await resolveStorageUrl(gsUrl);
      await _player.setUrl(url);

      _player.positionStream.listen((pos) {
        if (!mounted) return;
        setState(() {
          _position = pos;
        });
      });

      _player.durationStream.listen((dur) {
        if (!mounted || dur == null) return;
        setState(() {
          _duration = dur;
        });
      });

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo cargar el audio.';
        _loading = false;
      });
    }
  }

  Future<void> _openUrl(String? rawUrl) async {
    if (rawUrl == null || rawUrl.isEmpty) return;
    try {
      final url = await resolveStorageUrl(rawUrl);
      final uri = Uri.tryParse(url);
      if (uri == null) return;
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final voice = widget.voice;

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
            const SizedBox(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              )
            else
              Column(
                children: [
                  IconButton(
                    iconSize: 64,
                    icon: Icon(
                      _player.playing
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                    ),
                    onPressed: () {
                      if (_player.playing) {
                        _player.pause();
                      } else {
                        _player.play();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    min: 0,
                    max: _duration.inMilliseconds.toDouble().clamp(0, double.infinity),
                    value: _position.inMilliseconds
                        .clamp(0, _duration.inMilliseconds)
                        .toDouble(),
                    onChanged: (value) {
                      _player.seek(
                        Duration(milliseconds: value.round()),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_format(_position)),
                      Text(_format(_duration)),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 24),
            if (song.lyricsUrl != null)
              InkWell(
                onTap: () => _openUrl(song.lyricsUrl),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined),
                      const SizedBox(width: 8),
                      Text(
                        'Abrir letra (PDF)',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (song.demoVideoUrl != null) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _openUrl(song.demoVideoUrl),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_outline),
                      const SizedBox(width: 8),
                      Text(
                        'Ver demo (video)',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

