import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/track_types.dart';
import '../../core/models/song.dart';
import '../../core/providers.dart';

class CreateSongScreen extends ConsumerStatefulWidget {
  const CreateSongScreen({
    super.key,
    required this.choirId,
    this.song,
  });

  final String choirId;
  final Song? song;

  @override
  ConsumerState<CreateSongScreen> createState() => _CreateSongScreenState();
}

class _CreateSongScreenState extends ConsumerState<CreateSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _toneController = TextEditingController();

  final Set<String> _selectedVoices = {};
  final Map<String, String> _trackFiles = {}; // key -> file path
  String? _lyricsFilePath;
  bool _saving = false;
  String? _error;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.song != null;
    if (_isEditing) {
      _loadExistingSongData();
    }
  }

  void _loadExistingSongData() {
    final song = widget.song!;
    _titleController.text = song.title;
    _authorController.text = song.author ?? '';
    _toneController.text = song.tone ?? '';
    _selectedVoices.addAll(song.voicesAvailable);
    
    // Cargar rutas existentes de archivos (solo para referencia)
    for (final entry in song.audioUrls.entries) {
      _trackFiles[entry.key] = entry.value; // Guardamos la URL existente
    }
    if (song.lyricsUrl != null) {
      _lyricsFilePath = song.lyricsUrl; // Guardamos la URL existente
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _toneController.dispose();
    super.dispose();
  }

  static const _audioVideoExtensions = ['mp3', 'mp4', 'wav', 'mpeg'];

  Future<void> _pickTrackFile(String trackKey) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _audioVideoExtensions,
    );
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    final ext = path.split('.').last.toLowerCase();
    if (!_audioVideoExtensions.contains(ext)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solo .mp3, .mp4, .wav o .mpeg'),
          ),
        );
      }
      return;
    }
    setState(() => _trackFiles[trackKey] = path);
  }

  Future<void> _pickLyricsFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [kLyricsExtension],
    );
    if (result == null || result.files.single.path == null) return;
    setState(() => _lyricsFilePath = result.files.single.path);
  }

  Future<String> _uploadFile(String localPath, String storagePath) async {
    final ref = FirebaseStorage.instance.ref(storagePath);
    await ref.putFile(File(localPath));
    return ref.fullPath;
  }

  Future<void> _submit() async {
    _error = null;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'El título es obligatorio');
      return;
    }
    if (_selectedVoices.isEmpty) {
      setState(() => _error = 'Selecciona al menos una voz');
      return;
    }

    setState(() => _saving = true);

    try {
      final songsRepo = ref.read(songsRepositoryProvider);
      final songId = _isEditing ? widget.song!.id : songsRepo.generateSongId();
      final basePath = 'coroapp/choirs/${widget.choirId}/songs/$songId';

      final Map<String, String> audioUrls = {};
      String? lyricsUrl;
      String? demoVideoUrl;

      // Para edición: mantener URLs existentes si no se reemplazan
      final Map<String, String> existingAudioUrls = _isEditing ? widget.song!.audioUrls : {};
      final String? existingLyricsUrl = _isEditing ? widget.song!.lyricsUrl : null;

      for (final entry in _trackFiles.entries) {
        final trackKey = entry.key;
        final path = entry.value;
        
        // Si es una URL existente y no se seleccionó nuevo archivo, mantenerla
        if (_isEditing && existingAudioUrls.containsKey(trackKey) && 
            (path.startsWith('gs://') || path.startsWith('coroapp/') || path.startsWith('https://'))) {
          audioUrls[trackKey] = path; // Mantener URL existente
          if (trackKey == kDemoTrackKey) demoVideoUrl = path;
          continue;
        }
        
        // Nuevo archivo seleccionado: subirlo
        final ext = path.split('.').last;
        final storagePath = '$basePath/$trackKey.$ext';
        final fullPath = await _uploadFile(path, storagePath);
        audioUrls[trackKey] = fullPath;
        if (trackKey == kDemoTrackKey) demoVideoUrl = fullPath;
      }

      // Manejo de la letra
      if (_lyricsFilePath != null) {
        // Si es una URL existente y no se seleccionó nuevo archivo, mantenerla
        if (_isEditing && existingLyricsUrl != null && 
            (_lyricsFilePath!.startsWith('gs://') || _lyricsFilePath!.startsWith('coroapp/') || _lyricsFilePath!.startsWith('https://'))) {
          lyricsUrl = _lyricsFilePath; // Mantener URL existente
        } else {
          // Nuevo archivo seleccionado: subirlo
          final ext = _lyricsFilePath!.split('.').last.toLowerCase();
          if (ext != kLyricsExtension) {
            setState(() {
              _error = 'La letra debe ser un archivo PDF';
              _saving = false;
            });
            return;
          }
          lyricsUrl = await _uploadFile(
            _lyricsFilePath!,
            '$basePath/letra.$kLyricsExtension',
          );
        }
      }

      if (_isEditing) {
        await songsRepo.updateSong(
          songId: songId,
          title: title,
          author: _authorController.text.trim().isEmpty ? null : _authorController.text.trim(),
          tone: _toneController.text.trim().isEmpty ? null : _toneController.text.trim(),
          voicesAvailable: _selectedVoices.toList(),
          audioUrls: audioUrls,
          lyricsUrl: lyricsUrl,
          demoVideoUrl: demoVideoUrl,
        );
      } else {
        await songsRepo.createSong(
          songId: songId,
          choirId: widget.choirId,
          title: title,
          author: _authorController.text.trim().isEmpty ? null : _authorController.text.trim(),
          tone: _toneController.text.trim().isEmpty ? null : _toneController.text.trim(),
          voicesAvailable: _selectedVoices.toList(),
          audioUrls: audioUrls,
          lyricsUrl: lyricsUrl,
          demoVideoUrl: demoVideoUrl,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Canción actualizada' : 'Canción creada')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().contains('permission') || e.toString().contains('403')
            ? 'Sin permiso. Revisa reglas de Storage/Firestore.'
            : 'Error al crear: $e';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(currentAppUserProvider);
    final appUser = appUserAsync.value;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: getAppBarColor(appUser?.voice ?? ''),
        title: Text(_isEditing ? 'Editar canción' : 'Nueva canción'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Autor',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _toneController,
              decoration: const InputDecoration(
                labelText: 'Tono',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Voces (marca las que tenga la canción)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: kVoiceTrackKeys.map((voice) {
                final selected = _selectedVoices.contains(voice);
                return FilterChip(
                  label: Text(trackKeyToLabel(voice)),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedVoices.add(voice);
                      } else {
                        _selectedVoices.remove(voice);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Pistas (audio/video)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Formatos: .mp3, .mp4, .wav, .mpeg', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            ...allTrackKeys.map((key) {
              final path = _trackFiles[key];
              final isExistingUrl = _isEditing && path != null && 
                  (path.startsWith('gs://') || path.startsWith('coroapp/') || path.startsWith('https://'));
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 160,
                      child: Text(trackKeyToLabel(key)),
                    ),
                    Expanded(
                      child: Text(
                        path != null ? path.split('/').last : '—',
                        style: TextStyle(
                          fontSize: 12,
                          color: path != null 
                              ? (isExistingUrl ? Colors.blue : null)
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isExistingUrl)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Actual',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _saving ? null : () => _pickTrackFile(key),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: Text(isExistingUrl ? 'Reemplazar' : (path != null ? 'Cambiar' : 'Subir')),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            const Text('Letra (solo PDF)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final isExistingLyricsUrl = _isEditing && _lyricsFilePath != null && 
                    (_lyricsFilePath!.startsWith('gs://') || _lyricsFilePath!.startsWith('coroapp/') || _lyricsFilePath!.startsWith('https://'));
                return Row(
              children: [
                Expanded(
                  child: Text(
                    _lyricsFilePath != null ? _lyricsFilePath!.split('/').last : '—',
                    style: TextStyle(
                      fontSize: 12,
                      color: _lyricsFilePath != null 
                          ? (isExistingLyricsUrl ? Colors.blue : null)
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isExistingLyricsUrl)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Actual',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _saving ? null : _pickLyricsFile,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: Text(isExistingLyricsUrl ? 'Reemplazar' : (_lyricsFilePath != null ? 'Cambiar' : 'Subir PDF')),
                ),
              ],
            );
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Actualizar canción' : 'Crear canción'),
            ),
          ],
        ),
      ),
    );
  }
}
