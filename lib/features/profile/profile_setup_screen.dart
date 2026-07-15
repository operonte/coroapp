import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/track_types.dart';
import '../../core/models/choir.dart';
import '../../core/providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  String? _selectedChoirId;
  String? _selectedVoice;
  bool _saving = false;
  bool _initialized = false;

  final _voices = const ['primera_voz', 'tenor', 'bajo', 'contralto', 'soprano'];

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentAppUserProvider);
    final choirsAsync = ref.watch(choirsStreamProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error cargando perfil: $e')),
      ),
      data: (appUser) {
        if (appUser == null) {
          return const Scaffold(
            body: Center(child: Text('Usuario no encontrado')),
          );
        }

        if (!_initialized) {
          _selectedChoirId = appUser.choirId;
          _selectedVoice = appUser.voice;
          _initialized = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Configurar perfil'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coro',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
                const SizedBox(height: 8),
                choirsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error al cargar coros: $e'),
                  data: (List<Choir> choirs) {
                    final validChoirIds = choirs.map((c) => c.id).toList();
                    final dropdownValue = validChoirIds.contains(_selectedChoirId)
                        ? _selectedChoirId
                        : null;

                    return DropdownButtonFormField<String>(
                      initialValue: dropdownValue,
                      hint: const Text('Selecciona tu coro'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: choirs.map((choir) {
                        return DropdownMenuItem<String>(
                          value: choir.id,
                          child: Text(choir.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedChoirId = value;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Voz',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _voices.map((voice) {
                    final selected = _selectedVoice == voice;
                    return ChoiceChip(
                      label: Text(trackKeyToLabel(voice)),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedVoice = voice;
                        });
                      },
                    );
                  }).toList(),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            if (_selectedChoirId == null ||
                                _selectedChoirId!.isEmpty) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Debes indicar un coro'),
                                ),
                              );
                              return;
                            }
                            if (_selectedVoice == null) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Debes seleccionar tu voz'),
                                ),
                              );
                              return;
                            }

                            setState(() => _saving = true);
                            try {
                              await ref.read(userRepositoryProvider).updateProfile(
                                    uid: appUser.id,
                                    choirId: _selectedChoirId!,
                                    voice: _selectedVoice!,
                                  );
                            } catch (e) {
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Error al guardar: $e'),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _saving = false);
                              }
                            }
                          },
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
