import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../core/constants/track_types.dart';
import '../../core/providers.dart';

class CreateReminderScreen extends ConsumerStatefulWidget {
  const CreateReminderScreen({super.key});

  @override
  ConsumerState<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends ConsumerState<CreateReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  String _priority = 'medium';

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(currentAppUserProvider);
    final appUser = appUserAsync.value;

    if (appUser?.role != 'admin_coro') {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: getAppBarColor(appUser?.voice ?? ''),
          title: const Text('Acceso Denegado'),
        ),
        body: const Center(
          child: Text('Solo los jefes de grupo pueden crear recordatorios'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: getAppBarColor(appUser?.voice ?? ''),
        title: const Text('Nuevo Recordatorio'),
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
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Prioridad',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Baja')),
                  DropdownMenuItem(value: 'medium', child: Text('Media')),
                  DropdownMenuItem(value: 'high', child: Text('Alta')),
                ],
                onChanged: (value) => setState(() => _priority = value!),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _dueDate == null
                      ? 'Seleccionar fecha y hora'
                      : 'Vence: ${DateFormat('dd/MM/yyyy HH:mm').format(_dueDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDateTime,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saveReminder,
                child: const Text('Guardar Recordatorio'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _dueDate = DateTime(
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

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate() || _dueDate == null) return;

    final appUserAsync = ref.watch(currentAppUserProvider);
    final appUser = appUserAsync.value;

    try {
      await FirebaseFirestore.instance
          .collection('choirs')
          .doc(appUser!.id)
          .collection('reminders')
          .add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'priority': _priority,
        'dueDate': Timestamp.fromDate(_dueDate!),
        'createdBy': appUser!.id,
        'createdAt': Timestamp.now(),
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
