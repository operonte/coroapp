import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../core/constants/track_types.dart';
import '../../core/models/event.dart';
import '../../core/models/song.dart';
import '../../core/providers.dart';
import '../../core/services/storage_url_service.dart';
import 'create_event_screen.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.event});

  final Event event;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  AudioPlayer get _player => ref.read(globalAudioPlayerProvider);

  StreamSubscription<int?>? _indexSubscription;

  bool _loading = true;
  String? _error;
  List<Song> _playlistSongs = [];
  bool _playlistLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylistSongs();

    // Sincronizar el índice actual cuando el player avanza solo
    _indexSubscription = _player.currentIndexStream.listen((index) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _indexSubscription?.cancel();
    super.dispose();
  }

  // ─── Carga de canciones ───────────────────────────────────────────────────

  Future<void> _loadPlaylistSongs() async {
    if (!widget.event.hasPlaylist) {
      setState(() => _loading = false);
      return;
    }

    try {
      final songsRepo = ref.read(songsRepositoryProvider);
      final stream = songsRepo.watchAllSongsForChoir(widget.event.choirId);

      stream.listen((songs) async {
        // Preservar el orden definido en event.playlist
        final songMap = {for (final s in songs) s.id: s};
        final ordered = widget.event.playlist
            .map((id) => songMap[id])
            .whereType<Song>()
            .toList();

        if (mounted) {
          setState(() {
            _playlistSongs = ordered;
            _loading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // ─── Cargar TODA la playlist en just_audio de una vez ────────────────────

  Future<void> _loadPlaylistIntoPlayer({int startIndex = 0}) async {
    if (_playlistSongs.isEmpty) return;

    final appUser = ref.read(currentAppUserProvider).value;
    if (appUser == null) {
      _showError('Usuario no autenticado');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userVoice = appUser.voice ?? '';

      // Resolver todas las URLs en paralelo
      final sources = <AudioSource>[];
      for (final song in _playlistSongs) {
        final gsUrl = song.audioUrls[userVoice];
        if (gsUrl == null || gsUrl.isEmpty) {
          // Canción sin pista para esta voz: agregar silencio o simplemente omitir
          // (se omite para evitar errores en el player)
          continue;
        }
        try {
          final url = await resolveStorageUrl(gsUrl);
          sources.add(
            AudioSource.uri(
              Uri.parse(url),
              tag: MediaItem(
                id: '${song.id}_$userVoice',
                title: song.title,
                album: song.author ?? 'CoroApp',
                artUri: Uri.parse(
                  'https://firebasestorage.googleapis.com/v0/b/coroapp-e8122.firebasestorage.app/o/icon.png?alt=media',
                ),
              ),
            ),
          );
        } catch (_) {
          // Si una URL falla, simplemente la omitimos
        }
      }

      if (sources.isEmpty) {
        _showError('No hay pistas disponibles para tu voz (${userVoice.isEmpty ? "sin voz asignada" : userVoice})');
        return;
      }

      final playlist = ConcatenatingAudioSource(children: sources);
      await _player.setAudioSource(
        playlist,
        initialIndex: startIndex.clamp(0, sources.length - 1),
        preload: false,
      );

      setState(() {
        _loading = false;
        _playlistLoaded = true;
      });

      await _player.play();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Error al cargar la playlist: $e';
        });
      }
    }
  }

  // ─── Controles del player ─────────────────────────────────────────────────

  Future<void> _playOrPause() async {
    if (!_playlistLoaded) {
      await _loadPlaylistIntoPlayer(startIndex: 0);
      return;
    }
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _stop() async {
    await _player.stop();
    if (mounted) setState(() => _playlistLoaded = false);
  }

  Future<void> _previous() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  Future<void> _next() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  Future<void> _playFromIndex(int index) async {
    if (!_playlistLoaded) {
      await _loadPlaylistIntoPlayer(startIndex: index);
    } else {
      await _player.seek(Duration.zero, index: index);
      await _player.play();
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _error = message;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(currentAppUserProvider);
    final isAdmin = appUserAsync.value?.role == 'admin_coro';

    return appUserAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) => Scaffold(
        appBar: AppBar(
          backgroundColor: getAppBarColor(user?.voice ?? ''),
          title: Text(widget.event.title),
          actions: [
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar evento',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateEventScreen(
                      choirId: widget.event.choirId,
                      event: widget.event,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Encabezado del evento ──────────────────────────────────────
            Text(
              widget.event.eventTypeLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fecha y hora: ${_formatDateTime(widget.event.eventDateTime)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (widget.event.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Descripción:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                widget.event.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],

            if (!widget.event.hasPlaylist) ...[
              const SizedBox(height: 24),
              const Text('Este evento no tiene playlist de práctica'),
            ] else ...[
              const SizedBox(height: 24),

              // ── Título de la sección ────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.queue_music, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Playlist de práctica',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_playlistSongs.length} canciones',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                )
              else if (_playlistSongs.isEmpty)
                const Text('No se encontraron las canciones de la playlist')
              else ...[
                // ── Reproductor ──────────────────────────────────────────
                _buildPlayer(context),
                const SizedBox(height: 16),
                // ── Lista de canciones ───────────────────────────────────
                _buildSongList(context),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, stateSnap) {
        final state = stateSnap.data;
        final isPlaying = state?.playing ?? false;
        final isBuffering =
            state?.processingState == ProcessingState.loading ||
            state?.processingState == ProcessingState.buffering;
        final currentIdx = _player.currentIndex ?? 0;
        final currentSong = _playlistSongs.isNotEmpty &&
                currentIdx < _playlistSongs.length
            ? _playlistSongs[currentIdx]
            : null;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Column(
              children: [
                // Nombre de la canción actual
                Text(
                  currentSong?.title ?? 'Sin canción seleccionada',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (currentSong?.author?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    currentSong!.author!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 4),
                // Número de canción
                Text(
                  '${currentIdx + 1} / ${_playlistSongs.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),

                // ── Slider con tiempos reales ───────────────────────────
                StreamBuilder<Duration?>(
                  stream: _player.durationStream,
                  builder: (_, durationSnap) {
                    final total = durationSnap.data ?? Duration.zero;
                    return StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      builder: (_, posSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        final maxMs =
                            total.inMilliseconds.toDouble().clamp(1.0, double.infinity);
                        final posMs =
                            pos.inMilliseconds.toDouble().clamp(0.0, maxMs);

                        return Column(
                          children: [
                            Slider(
                              value: posMs,
                              max: maxMs,
                              onChanged: (v) => _player.seek(
                                Duration(milliseconds: v.round()),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(pos),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    _formatDuration(total),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 4),

                // ── Controles ───────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // ANTERIOR
                    IconButton(
                      iconSize: 36,
                      tooltip: 'Anterior',
                      onPressed: _playlistLoaded && _player.hasPrevious
                          ? _previous
                          : null,
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),

                    // PLAY / PAUSE / STOP
                    if (_playlistLoaded)
                      // Botón de detener
                      IconButton(
                        iconSize: 32,
                        tooltip: 'Detener',
                        onPressed: _stop,
                        icon: const Icon(Icons.stop_circle_outlined),
                        color: Theme.of(context).colorScheme.error,
                      ),

                    // PLAY/PAUSE grande central
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: isBuffering
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : FilledButton(
                              style: FilledButton.styleFrom(
                                shape: const CircleBorder(),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: _playOrPause,
                              child: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 36,
                              ),
                            ),
                    ),

                    // SIGUIENTE
                    IconButton(
                      iconSize: 36,
                      tooltip: 'Siguiente',
                      onPressed: _playlistLoaded && _player.hasNext
                          ? _next
                          : null,
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSongList(BuildContext context) {
    final currentIdx = _player.currentIndex ?? 0;

    return Column(
      children: List.generate(_playlistSongs.length, (index) {
        final song = _playlistSongs[index];
        final isCurrent = _playlistLoaded && index == currentIdx;

        return Card(
          color: isCurrent
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          margin: const EdgeInsets.only(bottom: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () => _playFromIndex(index),
            leading: CircleAvatar(
              backgroundColor: isCurrent
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: isCurrent && _player.playing
                  ? Icon(
                      Icons.graphic_eq,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCurrent
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
            title: Text(
              song.title,
              style: TextStyle(
                fontWeight:
                    isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: song.author?.isNotEmpty == true
                ? Text(song.author!)
                : null,
            trailing: Icon(
              Icons.play_arrow_rounded,
              color: isCurrent
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }),
    );
  }
}
