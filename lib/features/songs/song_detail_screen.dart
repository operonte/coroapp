import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/track_types.dart';
import '../../core/models/song.dart';
import '../../core/providers.dart';
import '../../core/services/storage_url_service.dart';
import '../../core/services/offline_audio_service.dart';
import '../../screens/pdf_viewer_screen.dart';
import 'create_song_screen.dart';

class SongDetailScreen extends ConsumerStatefulWidget {
  const SongDetailScreen({
    super.key,
    required this.song,
    required this.voice,
  });

  final Song song;
  final String voice;

  @override
  ConsumerState<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends ConsumerState<SongDetailScreen> {
  AudioPlayer get _player => ref.read(globalAudioPlayerProvider);
  
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  bool _loading = true;
  String? _error;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _resolvedAudioUrl;

  bool _downloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
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
      final offlineNotifier = ref.read(offlineAudioProvider.notifier);
      await offlineNotifier.checkStatus(widget.song.id, widget.voice);
      await offlineNotifier.checkPdfStatus(widget.song.id);

      final seq = _player.sequenceState;
      final currentSource = seq.currentSource;
      final mediaItem = currentSource != null ? currentSource.tag as MediaItem? : null;
      final targetId = '${widget.song.id}_${widget.voice}';

      if (mediaItem?.id != targetId) {
        setState(() => _loading = true);
        final localPath = await offlineNotifier.getLocalFilePathIfCached(widget.song.id, widget.voice);
        
        if (localPath != null) {
          await _player.setAudioSource(
            AudioSource.file(
              localPath,
              tag: MediaItem(
                id: targetId,
                title: widget.song.title,
                album: widget.song.author ?? 'CoroApp',
              ),
            ),
          );
          if (mounted) setState(() => _resolvedAudioUrl = localPath);
        } else {
          final url = await resolveStorageUrl(gsUrl);
          if (mounted) setState(() => _resolvedAudioUrl = url);
          await _player.setAudioSource(
            AudioSource.uri(
              Uri.parse(url),
              tag: MediaItem(
                id: targetId,
                title: widget.song.title,
                album: widget.song.author ?? 'CoroApp',
              ),
            ),
          );
        }
      } else {
        if (_player.audioSource is UriAudioSource) {
          _resolvedAudioUrl = (_player.audioSource as UriAudioSource).uri.toString();
        } else if (_player.audioSource is ProgressiveAudioSource) {
          _resolvedAudioUrl = (_player.audioSource as ProgressiveAudioSource).tag.id;
        }
      }

      _position = _player.position;
      _duration = _player.duration ?? Duration.zero;

      _positionSubscription = _player.positionStream.listen((pos) {
        if (!mounted) return;
        setState(() {
          _position = pos;
        });
      });

      _durationSubscription = _player.durationStream.listen((dur) {
        if (!mounted || dur == null) return;
        setState(() {
          _duration = dur;
        });
      });

      _stateSubscription = _player.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() {});
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

  Future<void> _toggleDownload() async {
    final offlineNotifier = ref.read(offlineAudioProvider.notifier);
    final isDownloaded = offlineNotifier.isDownloaded(widget.song.id, widget.voice);

    if (isDownloaded) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminar descargas'),
          content: const Text('¿Estás seguro de que deseas eliminar los archivos de este canto de tu dispositivo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await offlineNotifier.deleteAudio(widget.song.id, widget.voice);
        await offlineNotifier.deletePdf(widget.song.id);
        final seq = _player.sequenceState;
        final currentSource = seq.currentSource;
        final mediaItem = currentSource != null ? currentSource.tag as MediaItem? : null;
        if (mediaItem?.id == '${widget.song.id}_${widget.voice}') {
          await _init();
        }
      }
    } else {
      setState(() {
        _downloading = true;
        _downloadProgress = 0.0;
      });

      try {
        // Download audio first (80% of progress)
        await offlineNotifier.downloadAudio(
          song: widget.song,
          voice: widget.voice,
          onProgress: (progress) {
            setState(() {
              _downloadProgress = progress * 0.8;
            });
          },
        );

        // Download PDF if available (remaining 20% of progress)
        if (widget.song.lyricsUrl != null && widget.song.lyricsUrl!.isNotEmpty) {
          await offlineNotifier.downloadPdf(
            song: widget.song,
            onProgress: (progress) {
              setState(() {
                _downloadProgress = 0.8 + (progress * 0.2);
              });
            },
          );
        }

        setState(() {
          _downloadProgress = 1.0;
        });

        final seq = _player.sequenceState;
        final currentSource = seq.currentSource;
        final mediaItem = currentSource != null ? currentSource.tag as MediaItem? : null;
        if (mediaItem?.id == '${widget.song.id}_${widget.voice}') {
          await _init();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al descargar: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _downloading = false;
          });
        }
      }
    }
  }

  Future<void> _viewPdfInApp(String rawUrl, String title) async {
    final offlineNotifier = ref.read(offlineAudioProvider.notifier);
    final localPath = await offlineNotifier.getLocalPdfPathIfCached(widget.song.id);

    if (localPath != null) {
      try {
        final uri = Uri.file(localPath);
        final canLaunch = await canLaunchUrl(uri);
        if (canLaunch) {
          await launchUrl(uri);
          return;
        }
      } catch (e) {
        debugPrint('Error launching local PDF: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abriendo vista previa en línea (requiere internet)...')),
        );
      }
    }

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

  /// Construye la lista de opciones de pistas: solo las que tienen URL, y demo siempre.
  List<Widget> _buildTrackOptions({
    required Song song,
    required bool isAdmin,
    required String currentVoice,
  }) {
    final list = <Widget>[];
    for (final key in allTrackKeys) {
      // Usuarios normales: solo su voz + demo. El jefe ve todas las pistas.
      if (!isAdmin &&
          key != currentVoice &&
          key != kDemoTrackKey) {
        continue;
      }

      final url = key == kDemoTrackKey
          ? (song.audioUrls[kDemoTrackKey] ?? song.demoVideoUrl)
          : song.audioUrls[key];
      final label = trackKeyToLabel(key);
      if (key == kDemoTrackKey) {
        // Demo siempre visible
        if (url != null && url.isNotEmpty) {
          list.add(
            _MediaOption(
              icon: Icons.play_circle_outline,
              title: label,
              onOpen: () => _openInExternalApp(url),
            ),
          );
        } else {
          list.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.play_circle_outline, size: 24, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 12),
                  Text(
                    '$label (vacío)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
          );
        }
      } else if (url != null && url.isNotEmpty) {
        list.add(
          _MediaOption(
            icon: Icons.music_note,
            title: label,
            onOpen: () => _openInExternalApp(url),
          ),
        );
      }
    }
    return list;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final voice = widget.voice;
    final appUserAsync = ref.watch(currentAppUserProvider);
    final appUser = appUserAsync.value;
    final isAdmin = appUser?.role == 'admin_coro';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: getAppBarColor(voice),
        title: Text(song.title),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar canción',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateSongScreen(
                      choirId: song.choirId,
                      song: song,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voz: ${trackKeyToLabel(voice)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (song.tone != null)
                      Text(
                        'Tono: ${song.tone}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
                _downloading
                    ? SizedBox(
                        width: 48,
                        height: 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: _downloadProgress,
                              strokeWidth: 3,
                            ),
                            Text(
                              '${(_downloadProgress * 100).round()}%',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : Consumer(
                        builder: (context, ref, _) {
                          final offline = ref.watch(offlineAudioProvider);
                          final isCached = offline['${song.id}_$voice'] ?? false;

                          return IconButton(
                            icon: Icon(
                              isCached
                                  ? Icons.download_done_rounded
                                  : Icons.download_rounded,
                              color: isCached
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            tooltip: isCached
                                ? 'Eliminar descarga local'
                                : 'Descargar para ensayar sin internet',
                            onPressed: _toggleDownload,
                          );
                        },
                      ),
              ],
            ),
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
            _SectionTitle(title: 'Pistas'),
            ..._buildTrackOptions(
              song: song,
              isAdmin: isAdmin,
              currentVoice: voice,
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: 'Letra'),
            if (song.lyricsUrl != null)
              _MediaOption(
                icon: Icons.description_outlined,
                title: 'Letra (PDF)',
                onOpen: () => _openInExternalApp(song.lyricsUrl),
                onViewInApp: () => _viewPdfInApp(song.lyricsUrl!, song.title),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sin letra',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
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
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
