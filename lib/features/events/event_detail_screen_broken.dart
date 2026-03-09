import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../core/models/event.dart';
import '../../core/models/song.dart';
import '../../core/providers.dart';
import '../../core/services/storage_url_service.dart';
import 'create_event_screen.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  late final AudioPlayer _player;
  bool _loading = true;
  String? _error;
  int _currentSongIndex = 0;
  List<Song> _playlistSongs = [];
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _loadPlaylistSongs();
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    // Configurar listeners una sola vez - JustAudioBackground ya se inicializó en main.dart
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

    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylistSongs() async {
    if (!widget.event.hasPlaylist) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final songsRepo = ref.read(songsRepositoryProvider);
      final stream = songsRepo.watchAllSongsForChoir(widget.event.choirId);
      
      stream.listen((songs) {
        final playlistSongs = songs.where((song) => 
          widget.event.playlist.contains(song.id)
        ).toList();
        
        // Validar edge cases
        if (widget.event.playlist.isNotEmpty && playlistSongs.isEmpty) {
          // Hay canciones en la playlist pero no se encontraron en la DB
          if (mounted) {
            setState(() {
              _error = 'Algunas canciones de la playlist no están disponibles';
              _loading = false;
            });
          }
          return;
        }
        
        if (mounted) {
          setState(() {
            _playlistSongs = playlistSongs;
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
      if (appUser == null) return;

      final userVoice = appUser.voice ?? '';
      final gsUrl = song.audioUrls[userVoice];
      
      if (gsUrl == null || gsUrl.isEmpty) {
        setState(() {
          _error = 'No hay audio configurado para esta voz.';
          _loading = false;
        });
        return;
      }

      setState(() {
        _loading = true;
        _error = null;
      });

      // Crear AudioPlayer nuevo como en SongDetailScreen
      final player = AudioPlayer();
      
      try {
        final url = await resolveStorageUrl(gsUrl);
        await player.setAudioSource(
          AudioSource.uri(
            Uri.parse(url),
            tag: MediaItem(
              id: '${song.id}_$userVoice',
              title: song.title,
              album: song.author ?? 'CoroApp',
            ),
          ),
        );

        player.positionStream.listen((pos) {
          if (!mounted) return;
          setState(() {
            _position = pos;
          });
        });

        player.durationStream.listen((dur) {
          if (!mounted || dur == null) return;
          setState(() {
            _duration = dur;
          });
        });

        // Auto-avance para playlist
        player.playerStateStream.listen((state) {
          if (!mounted) return;
          if (state.processingState == ProcessingState.completed) {
            player.dispose();
            playNext();
          }
        });

        await player.play();
        
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      } catch (e) {
        player.dispose();
        if (mounted) {
          setState(() {
            _error = 'No se pudo cargar el audio: $e';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error general: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> playNext() async {
    if (_currentSongIndex < _playlistSongs.length - 1) {
      // Detener reproducción actual antes de pasar a siguiente
      await _player.stop();
      setState(() {
        _currentSongIndex++;
      });
      await _playSong(_playlistSongs[_currentSongIndex]);
    } else {
      // No hay más canciones
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay más canciones con pista para tu voz')),
        );
      }
    }
  }

  Future<void> playPrevious() async {
    if (_currentSongIndex > 0) {
      // Detener reproducción actual antes de pasar a anterior
      await _player.stop();
      setState(() {
        _currentSongIndex--;
      });
      await _playSong(_playlistSongs[_currentSongIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(currentAppUserProvider);
    final isAdmin = appUserAsync.value?.role == 'admin_coro';

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
                Text(
                  'Playlist de práctica (${widget.event.playlist.length} canciones)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  )
                else if (_playlistSongs.isEmpty)
                  const Text('No se encontraron las canciones de la playlist')
                else ...[
                  // Reproductor actual
                  if (_playlistSongs.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              _playlistSongs[_currentSongIndex].title,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            if (_playlistSongs[_currentSongIndex].author?.isNotEmpty == true)
                              Text(
                                _playlistSongs[_currentSongIndex].author!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            const SizedBox(height: 16),
                            StreamBuilder<Duration>(
                              stream: _player.positionStream,
                              builder: (context, snapshot) {
                                final position = snapshot.data ?? Duration.zero;
                                return Slider(
                                  value: position.inMilliseconds.toDouble(),
                                  max: 300000, // 5 minutos máximo como fallback
                                  onChanged: (value) {
                                    _player.seek(Duration(milliseconds: value.round()));
                                  },
                                );
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: _currentSongIndex > 0 ? playPrevious : null,
                                  icon: const Icon(Icons.skip_previous),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    // Detener reproducción actual antes de iniciar nueva
                                    await _player.stop();
                                    await _playSong(_playlistSongs[_currentSongIndex]);
                                  },
                                  icon: Icon(_player.playing ? Icons.pause : Icons.play_arrow),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    // Detener reproducción actual antes de pasar a siguiente
                                    await _player.stop();
                                    playNext();
                                  },
                                  icon: const Icon(Icons.skip_next),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Lista de canciones
                  Expanded(
                    child: ListView.builder(
                      itemCount: _playlistSongs.length,
                      itemBuilder: (context, index) {
                        final song = _playlistSongs[index];
                        final isCurrentSong = index == _currentSongIndex;
                        return Card(
                          color: isCurrentSong 
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: ListTile(
                            title: Text(song.title),
                            subtitle: song.author?.isNotEmpty == true 
                                ? Text(song.author!)
                                : null,
                            trailing: isCurrentSong && _player.playing
                                ? const Icon(Icons.play_arrow)
                                : null,
                            onTap: () {
                              setState(() {
                                _currentSongIndex = index;
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
}

Color getAppBarColor(String voice) {
  switch (voice.toLowerCase()) {
    case 'soprano':
      return const Color(0xFFE91E63);
    case 'alto':
      return const Color(0xFF9C27B0);
    case 'tenor':
      return const Color(0xFF2196F3);
    case 'bajo':
      return const Color(0xFF4CAF50);
    default:
      return const Color(0xFF2C3E80);
  }
}
