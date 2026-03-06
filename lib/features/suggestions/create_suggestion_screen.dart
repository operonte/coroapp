import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/track_types.dart';
import '../../core/providers.dart';

class CreateSuggestionScreen extends ConsumerStatefulWidget {
  const CreateSuggestionScreen({super.key});

  @override
  ConsumerState<CreateSuggestionScreen> createState() => _CreateSuggestionScreenState();
}

class _CreateSuggestionScreenState extends ConsumerState<CreateSuggestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'general';
  int _rating = 5;
  String? _imagePath;

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(currentAppUserProvider);
    final appUser = appUserAsync.value;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: getAppBarColor(appUser?.voice ?? ''),
        title: const Text('Nueva Sugerencia'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) => value?.isEmpty ?? true ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General')),
                  DropdownMenuItem(value: 'bug', child: Text('Reportar error')),
                  DropdownMenuItem(value: 'improvement', child: Text('Mejora')),
                  DropdownMenuItem(value: 'new_feature', child: Text('Nueva función')),
                ],
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 16),
              const Text('Calificación de la app:'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setState(() => _rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: Text(_imagePath == null ? 'Adjuntar imagen' : 'Cambiar imagen'),
              ),
              if (_imagePath != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(_imagePath!, height: 100),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saveSuggestion,
                child: const Text('Enviar Sugerencia'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  Future<void> _saveSuggestion() async {
    if (!_formKey.currentState!.validate()) return;

    final appUserAsync = ref.watch(currentAppUserProvider);
    final appUser = appUserAsync.value;

    try {
      await FirebaseFirestore.instance.collection('suggestions').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'type': _type,
        'rating': _rating,
        'imagePath': _imagePath,
        'status': 'pending',
        'createdBy': appUser!.id,
        'createdByName': appUser.displayName,
        'createdAt': Timestamp.now(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sugerencia enviada correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
