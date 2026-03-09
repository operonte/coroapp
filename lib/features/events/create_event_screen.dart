import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/track_types.dart';
import '../../core/models/event.dart';
import '../../core/models/song.dart';
import '../../core/providers.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({
    super.key,
    required this.choirId,
    this.event,
  });

  final String choirId;
  final Event? event;

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedEventType;
  DateTime? _eventDateTime;
  bool _loading = false;
  String? _error;

  Set<String> _selectedSongs = {};
  List<Song> _availableSongs = [];

  final _eventTypes = const [
    {'value': 'ensayo', 'label': 'Ensayo'},
    {'value': 'presentacion', 'label': 'Presentación'},
    {'value': 'reunion', 'label': 'Reunión'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _loadEventData();
    }
    _loadAvailableSongs();
  }

  void _loadEventData() {
    final event = widget.event!;
    _titleController.text = event.title;
    _descriptionController.text = widget.event?.description ?? '';
    _selectedEventType = event.eventType;
    _eventDateTime = event.eventDateTime;
    _selectedSongs = Set.from(event.playlist);
  }

  Future<void> _loadAvailableSongs() async {
    final songsRepo = ref.read(songsRepositoryProvider);
    final stream = songsRepo.watchAllSongsForChoir(widget.choirId);
    stream.listen((songs) {
      if (mounted) {
        setState(() {
          _availableSongs = songs;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _hasPlaylist => _selectedEventType == 'ensayo' || _selectedEventType == 'presentacion';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final appUser = ref.read(currentAppUserProvider).value;
    if (appUser == null) {
      setState(() => _error = 'Debes estar autenticado para crear eventos');
      return;
    }

    if (_selectedEventType == null) {
      setState(() => _error = 'Selecciona el tipo de evento');
      return;
    }

    if (_eventDateTime == null) {
      setState(() => _error = 'Selecciona la fecha y hora del evento');
      return;
    }

    if (_hasPlaylist && _selectedSongs.isEmpty) {
      setState(() => _error = 'Selecciona al menos una canción para la playlist');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final eventsRepo = ref.read(eventsRepositoryProvider);

      // Calcular auto-eliminación: 20 minutos después del evento
      final autoDelete = _eventDateTime!.add(const Duration(minutes: 20));

      if (widget.event != null) {
        // Editar evento existente
        await eventsRepo.updateEvent(
          eventId: widget.event!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          eventType: _selectedEventType!,
          eventDateTime: _eventDateTime!,
          autoDeleteDateTime: autoDelete,
          playlist: _hasPlaylist ? _selectedSongs.toList() : [],
        );
      } else {
        // Crear nuevo evento
        final eventId = eventsRepo.generateEventId();
        await eventsRepo.createEvent(
          eventId: eventId,
          choirId: widget.choirId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          eventType: _selectedEventType!,
          eventDateTime: _eventDateTime!,
          autoDeleteDateTime: autoDelete,
          createdBy: appUser.id,
          playlist: _hasPlaylist ? _selectedSongs.toList() : [],
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          title: Text(widget.event != null ? 'Editar Evento' : 'Nuevo Evento'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título del evento *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el título del evento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedEventType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de evento *',
                  border: OutlineInputBorder(),
                ),
                items: _eventTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEventType = value;
                    if (!_hasPlaylist) {
                      _selectedSongs.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Fecha y hora del evento'),
                subtitle: Text(_eventDateTime != null 
                    ? _formatDateTime(_eventDateTime!)
                    : 'Selecciona fecha y hora'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectEventDateTime,
              ),
              const SizedBox(height: 16),
              if (_hasPlaylist) ...[
                const SizedBox(height: 24),
                const Text(
                  'Playlist de práctica',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                if (_availableSongs.isEmpty)
                  const Text('Cargando canciones...')
                else ...[
                  ..._availableSongs.map((song) {
                    final isSelected = _selectedSongs.contains(song.id);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedSongs.add(song.id);
                          } else {
                            _selectedSongs.remove(song.id);
                          }
                        });
                      },
                      title: Text(song.title),
                      subtitle: song.author?.isNotEmpty == true 
                          ? Text(song.author!)
                          : null,
                    );
                  }),
                ],
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.event != null ? 'Actualizar Evento' : 'Crear Evento'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectEventDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDateTime ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_eventDateTime ?? now),
      );
      
      if (time != null) {
        setState(() {
          _eventDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
