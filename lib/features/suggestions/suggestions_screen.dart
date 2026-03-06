import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../core/constants/track_types.dart';
import '../../core/providers.dart';
import 'create_suggestion_screen.dart';

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen> {
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
        title: const Text('Sugerencias y Comentarios'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateSuggestionScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Nueva Sugerencia'),
              style: ElevatedButton.styleFrom(
                backgroundColor: getAppBarColor(appUser.voice ?? ''),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('suggestions')
                  .where('createdBy', isEqualTo: appUser.id)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No has enviado sugerencias aún'),
                  );
                }

                final suggestions = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = suggestions[index];
                    final data = suggestion.data() as Map<String, dynamic>;
                    final createdAt = (data['createdAt'] as Timestamp).toDate();
                    final status = data['status'] ?? 'pending';

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(status),
                          child: Icon(
                            _getSuggestionIcon(data['type'] ?? 'general'),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(data['title'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['description'] ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              'Enviado: ${DateFormat('dd/MM/yyyy').format(createdAt)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Estado: ${_getStatusText(status)}',
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showSuggestionDetail(suggestion),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_review':
        return Colors.blue;
      case 'responded':
        return Colors.green;
      case 'implemented':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getSuggestionIcon(String type) {
    switch (type) {
      case 'bug':
        return Icons.bug_report;
      case 'improvement':
        return Icons.trending_up;
      case 'new_feature':
        return Icons.lightbulb;
      default:
        return Icons.chat;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'in_review':
        return 'En revisión';
      case 'responded':
        return 'Respondido';
      case 'implemented':
        return 'Implementado';
      default:
        return 'Desconocido';
    }
  }

  void _showSuggestionDetail(DocumentSnapshot suggestion) {
    final data = suggestion.data() as Map<String, dynamic>;
    final createdAt = (data['createdAt'] as Timestamp).toDate();
    final respondedAt = data['respondedAt'] != null
        ? (data['respondedAt'] as Timestamp).toDate()
        : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['title'] ?? ''),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Descripción: ${data['description'] ?? ''}'),
              const SizedBox(height: 8),
              Text('Tipo: ${data['type'] ?? 'general'}'),
              Text('Estado: ${_getStatusText(data['status'] ?? 'pending')}'),
              Text('Enviado: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}'),
              if (respondedAt != null)
                Text('Respondido: ${DateFormat('dd/MM/yyyy HH:mm').format(respondedAt)}'),
              if (data['developerResponse'] != null) ...[
                const SizedBox(height: 16),
                const Text('Respuesta del desarrollador:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(data['developerResponse']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
