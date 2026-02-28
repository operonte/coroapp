import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/song.dart';
import '../../core/services/storage_url_service.dart';
import '../../screens/pdf_viewer_screen.dart';

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
  String? _resolvedAudioUrl;

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
      if (mounted) setState(() => _resolvedAudioUrl = url);
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: '${widget.song.id}_${widget.voice}',
            title: widget.song.title,
            album: widget.song.author ?? 'CoroApp',
          ),
        ),
      );

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
      String? fallbackUrl;
      try {
        fallbackUrl = await resolveStorageUrl(gsUrl);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _error = 'No se pudo cargar aquí. Puedes abrirlo con otra app.';
          _loading = false;
          _resolvedAudioUrl = fallbackUrl;
        });
      }
    }
  }

  Future<void> _viewPdfInApp(String rawUrl, String title) async {
    String? url;
    try {
      url = await resolveStorageUrl(rawUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('404')
                  ? 'PDF no encontrado'
                  : 'No se pudo cargar el PDF',
            ),
          ),
        );
      }
      return;
    }
    if (url.isEmpty) return;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          pdfUrl: url!,
          title: title,
        ),
      ),
    );
  }

  Future<void> _openInExternalApp(String? rawUrl, {String? directUrl}) async {
    String? url = directUrl;
    if (url == null && rawUrl != null && rawUrl.isNotEmpty) {
      try {
        url = await resolveStorageUrl(rawUrl);
      } catch (e) {
        if (mounted) {
          final msg = e.toString().contains('404') || e.toString().contains('not found')
              ? 'Archivo no encontrado en Storage'
              : (e.toString().contains('403') || e.toString().contains('permission')
                  ? 'Sin permiso de acceso. Revisa las reglas de Storage.'
                  : 'No se pudo obtener el enlace');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
        return;
      }
    }
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay app para abrir este archivo')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir')),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  if (_resolvedAudioUrl != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _openInExternalApp(null, directUrl: _resolvedAudioUrl),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Abrir con app externa'),
                    ),
                  ],
                ],
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
                  if (_resolvedAudioUrl != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _openInExternalApp(null, directUrl: _resolvedAudioUrl),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Abrir con app externa'),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 24),
            if (song.lyricsUrl != null)
              _MediaOption(
                icon: Icons.description_outlined,
                title: 'Letra (PDF)',
                onOpen: () => _openInExternalApp(song.lyricsUrl),
                onViewInApp: () => _viewPdfInApp(song.lyricsUrl!, song.title),
              ),
            if (song.demoVideoUrl != null)
              _MediaOption(
                icon: Icons.play_circle_outline,
                title: 'Demo (video)',
                onOpen: () => _openInExternalApp(song.demoVideoUrl),
              ),
          ],
        ),
      ),
    );
  }
}

class _MediaOption extends StatelessWidget {
  const _MediaOption({
    required this.icon,
    required this.title,
    required this.onOpen,
    this.onViewInApp,
  });

  final IconData icon;
  final String title;
  final VoidCallback onOpen;
  final VoidCallback? onViewInApp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  onViewInApp != null
                      ? 'Ver en la app o abrir con otra'
                      : 'Abrir con app externa',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          if (onViewInApp != null) ...[
            FilledButton.tonalIcon(
              onPressed: onViewInApp,
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('Ver'),
            ),
            const SizedBox(width: 8),
          ],
          FilledButton.tonalIcon(
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Abrir'),
          ),
        ],
      ),
    );
  }
}
