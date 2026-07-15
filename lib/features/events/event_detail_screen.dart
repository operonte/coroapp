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

  StreamSubscription<PlayerState>? _playerStateSubscription;

  bool _loading = true;
  String? _error;
  int _currentSongIndex = 0;
  int _retryCount = 0;
  List<Song> _playlistSongs = [];
  bool _isPlaying = false;
  bool _isPlayingAll = false;

  @override
  void initState() {
    super.initState();
    _setupPlayerListener();
    _loadPlaylistSongs();
  }

  void _setupPlayerListener() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (!mounted) return;

      // Sincronizar el estado visual de reproducción
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }

      // Avanzar a la siguiente canción al completar
      if (!state.playing &&
          state.processingState == ProcessingState.completed) {
        _playNext();
      }
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPlaylistSongs() async {
    if (!widget.event.hasPlaylist) {
      setState(() => _loading = false);
      return;
    }

    try {
      final songsRepo = ref.read(songsRepositoryProvider);
      final stream = songsRepo.watchAllSongsForChoir(widget.event.choirId);

      stream.listen((songs) {
        // BUGFIX: Preservar el orden definido en event.playlist
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

  Future<void> _playSong(Song song) async {
    try {
      final appUser = ref.read(currentAppUserProvider).value;
      if (appUser == null) {
        _handleError('Usuario no autenticado');
        return;
      }

      final userVoice = appUser.voice ?? '';
      final gsUrl = song.audioUrls[userVoice];

      if (gsUrl == null || gsUrl.isEmpty) {
        _handleError('Sin pista para tu voz', shouldSkip: true);
        return;
      }

      setState(() {
        _loading = true;
        _error = null;
        _retryCount = 0;
      });

      await _attemptPlayback(gsUrl, song, userVoice);
    } catch (e) {
      _handleError('Error inesperado: $e', shouldSkip: true);
    }
  }

  Future<void> _attemptPlayback(
    String gsUrl,
    Song song,
    String userVoice,
  ) async {
    try {
      final url = await resolveStorageUrl(gsUrl);
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: '${song.id}_$userVoice',
            title: song.title,
            album: song.author ?? 'CoroApp',
          ),
        ),
      );
      await _player.play();

      if (mounted) {
        setState(() {
          _loading = false;
          _isPlaying = true;
        });
      }
    } catch (e) {
      _retryCount++;

      if (_retryCount <= 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reintentando ($_retryCount/3)...'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
        await Future.delayed(Duration(seconds: _retryCount));
        await _attemptPlayback(gsUrl, song, userVoice);
      } else {
        _handleError(
          'No se pudo cargar después de 3 intentos',
          shouldSkip: true,
        );
      }
    }
  }

  void _handleError(String message, {bool shouldSkip = false}) {
    if (mounted) {
      setState(() {
        _error = message;
        _loading = false;
        _isPlaying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );

      if (shouldSkip) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _playNext();
        });
      }
    }
  }

  Future<void> _playNext() async {
    if (_playlistSongs.isEmpty) return;

    if (_currentSongIndex < _playlistSongs.length - 1) {
      setState(() {
        _currentSongIndex++;
        _retryCount = 0;
      });
      await _playSong(_playlistSongs[_currentSongIndex]);
    } else {
      // Fin de la playlist
      if (_isPlayingAll) {
        // Reiniciar desde el principio en modo "Escuchar Todo"
        setState(() {
          _currentSongIndex = 0;
          _retryCount = 0;
        });
        await _playSong(_playlistSongs[_currentSongIndex]);
      } else {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎵 Playlist completada'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _playAll() async {
    if (_playlistSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay canciones en la playlist')),
      );
      return;
    }

    setState(() {
      _currentSongIndex = 0;
      _retryCount = 0;
      _isPlayingAll = true;
    });

    await _playSong(_playlistSongs[0]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔁 Reproducción continua activada'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _stopAll() async {
    await _player.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _isPlayingAll = false;
      });
    }
  }

  // BUGFIX: separar toggle de play/pause correctamente
  Future<void> _togglePlayPause() async {
    if (_player.playing) {
      // Pausar
      await _player.pause();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      // BUGFIX: si ya hay una fuente cargada, reanudar en lugar de reiniciar
      if (_player.audioSource != null &&
          _player.processingState != ProcessingState.idle) {
        await _player.play();
        if (mounted) setState(() => _isPlaying = true);
      } else {
        // Sin fuente cargada: iniciar desde el índice actual
        await _playSong(_playlistSongs[_currentSongIndex]);
      }
    }
  }

  Future<void> _togglePlayAll() async {
    if (_isPlayingAll) {
      await _stopAll();
    } else {
      await _playAll();
    }
  }

  Future<void> _playPrevious() async {
    if (_currentSongIndex > 0) {
      setState(() {
        _currentSongIndex--;
        _retryCount = 0;
      });
      await _playSong(_playlistSongs[_currentSongIndex]);
    }
  }

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
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateEventScreen(
                        choirId: widget.event.choirId,
                        event: widget.event,
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
              Text(
                widget.event.eventTypeLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fecha y hora: ${_formatDateTime(widget.event.eventDateTime)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (widget.event.description.isNotEmpty) ...[
                Text(
                  'Descripción:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.event.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
              if (widget.event.hasPlaylist) ...[
                const SizedBox(height: 24),
                Text(
                  'Playlist de práctica (${_playlistSongs.length} canciones)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                // Botón principal: Escuchar Todo / Detener
                FilledButton.icon(
                  onPressed:
                      _playlistSongs.isEmpty ? null : _togglePlayAll,
                  icon: Icon(_isPlayingAll ? Icons.stop : Icons.repeat),
                  label: Text(
                    _isPlayingAll ? 'Detener reproducción' : 'Escuchar Todo',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _isPlayingAll
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: _isPlayingAll
                        ? Theme.of(context).colorScheme.onError
                        : Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                else if (_playlistSongs.isEmpty)
                  const Text('No se encontraron las canciones de la playlist')
                else ...[
                  // Reproductor actual
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            _playlistSongs[_currentSongIndex].title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_playlistSongs[_currentSongIndex]
                                  .author
                                  ?.isNotEmpty ==
                              true)
                            Text(
                              _playlistSongs[_currentSongIndex].author!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          const SizedBox(height: 16),
                          // BUGFIX: Slider con duración real del audio
                          StreamBuilder<Duration?>(
                            stream: _player.durationStream,
                            builder: (context, durationSnapshot) {
                              final totalDuration =
                                  durationSnapshot.data ?? Duration.zero;
                              return StreamBuilder<Duration>(
                                stream: _player.positionStream,
                                builder: (context, posSnapshot) {
                                  final position =
                                      posSnapshot.data ?? Duration.zero;
                                  final maxMs = totalDuration.inMilliseconds
                                      .toDouble()
                                      .clamp(1.0, double.infinity);
                                  final posMs = position.inMilliseconds
                                      .toDouble()
                                      .clamp(0.0, maxMs);
                                  return Column(
                                    children: [
                                      Slider(
                                        value: posMs,
                                        max: maxMs,
                                        onChanged: (value) {
                                          _player.seek(
                                            Duration(
                                              milliseconds: value.round(),
                                            ),
                                          );
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatDuration(position),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                            Text(
                                              _formatDuration(totalDuration),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: _currentSongIndex > 0
                                    ? _playPrevious
                                    : null,
                                icon: const Icon(Icons.skip_previous),
                              ),
                              IconButton(
                                iconSize: 40,
                                onPressed: _togglePlayPause,
                                icon: Icon(
                                  _isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    _currentSongIndex <
                                        _playlistSongs.length - 1
                                    ? _playNext
                                    : null,
                                icon: const Icon(Icons.skip_next),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Lista de canciones numeradas
                  Expanded(
                    child: ListView.builder(
                      itemCount: _playlistSongs.length,
                      itemBuilder: (context, index) {
                        final song = _playlistSongs[index];
                        final isCurrentSong = index == _currentSongIndex;
                        return Card(
                          color: isCurrentSong
                              ? Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                              : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCurrentSong
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isCurrentSong
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              song.title,
                              style: isCurrentSong
                                  ? const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    )
                                  : null,
                            ),
                            subtitle: song.author?.isNotEmpty == true
                                ? Text(song.author!)
                                : null,
                            trailing: isCurrentSong && _isPlaying
                                ? const Icon(Icons.graphic_eq)
                                : const Icon(Icons.play_arrow),
                            onTap: () {
                              setState(() {
                                _currentSongIndex = index;
                                _isPlayingAll = false;
                              });
                              _playSong(song);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ] else ...[
                const Text('Este evento no tiene playlist de práctica'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
