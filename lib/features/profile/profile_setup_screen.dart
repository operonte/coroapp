import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  final _voices = const ['tenor', 'bajo', 'contralto', 'soprano'];

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentAppUserProvider);

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

        _selectedChoirId ??= appUser.choirId;
        _selectedVoice ??= appUser.voice;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Configurar perfil'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Coro ID'),
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(
                    text: _selectedChoirId ?? '',
                  ),
                  onChanged: (value) => _selectedChoirId = value.trim(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ej: coro_central_001',
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Voz'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _voices.map((voice) {
                    final selected = _selectedVoice == voice;
                    return ChoiceChip(
                      label: Text(voice),
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
                            if (_selectedChoirId == null ||
                                _selectedChoirId!.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Debes indicar un coro'),
                                ),
                              );
                              return;
                            }
                            if (_selectedVoice == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Debes seleccionar tu voz'),
                                ),
                              );
                              return;
                            }

                            setState(() => _saving = true);
                            try {
                              final usersCol = ref
                                  .read(firestoreProvider)
                                  .collection('users');
                              await usersCol.doc(appUser.id).update({
                                'choirId': _selectedChoirId,
                                'voice': _selectedVoice,
                              });
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

