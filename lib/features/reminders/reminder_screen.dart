import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../core/constants/track_types.dart';
import '../../core/providers.dart';
import 'create_reminder_screen.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(currentAppUserProvider);
    final appUser = appUserAsync.value;

    if (appUser == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: getAppBarColor(appUser.voice ?? ''),
        title: const Text('Recordatorios'),
        actions: [
          if (appUser.role == 'admin_coro')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateReminderScreen()),
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('choirs')
            .doc(appUser.id)
            .collection('reminders')
            .where('dueDate', isGreaterThanOrEqualTo: DateTime.now())
            .orderBy('dueDate', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay recordatorios activos'),
            );
          }

          final reminders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              final data = reminder.data() as Map<String, dynamic>;
              final dueDate = (data['dueDate'] as Timestamp).toDate();
              final isOverdue = dueDate.isBefore(DateTime.now());

              return Card(
                color: isOverdue ? Colors.red[50] : null,
                child: ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: isOverdue ? Colors.red : getAppBarColor(appUser.voice ?? ''),
                  ),
                  title: Text(data['title'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['description'] ?? ''),
                      const SizedBox(height: 4),
                      Text(
                        'Vence: ${DateFormat('dd/MM/yyyy HH:mm').format(dueDate)}',
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.grey[600],
                          fontWeight: isOverdue ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                  trailing: isOverdue
                      ? const Icon(Icons.warning, color: Colors.red)
                      : Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
