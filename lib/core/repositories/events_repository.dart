import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event.dart';

class EventsRepository {
  EventsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _eventsCol =>
      _firestore.collection('events');

  /// Obtiene eventos activos de un coro ordenados por fecha
  Stream<List<Event>> watchEventsForChoir(String choirId) {
    final now = Timestamp.now();
    return _eventsCol
        .where('choirId', isEqualTo: choirId)
        .where('isActive', isEqualTo: true)
        .where('autoDeleteDateTime', isGreaterThan: now)
        .orderBy('eventDateTime')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Event.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// Genera un ID libre para un nuevo evento
  String generateEventId() => _eventsCol.doc().id;

  /// Crea un nuevo evento
  Future<void> createEvent({
    required String eventId,
    required String choirId,
    required String title,
    required String description,
    required String eventType,
    required DateTime eventDateTime,
    required DateTime autoDeleteDateTime,
    required String createdBy,
    required List<String> playlist,
  }) async {
    await _eventsCol.doc(eventId).set({
      'choirId': choirId,
      'title': title,
      'description': description,
      'eventType': eventType,
      'eventDateTime': Timestamp.fromDate(eventDateTime),
      'autoDeleteDateTime': Timestamp.fromDate(autoDeleteDateTime),
      'createdBy': createdBy,
      'createdAt': Timestamp.now(),
      'isActive': true,
      'playlist': playlist,
    });
  }

  /// Actualiza un evento existente
  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required String eventType,
    required DateTime eventDateTime,
    required DateTime autoDeleteDateTime,
    required List<String> playlist,
  }) async {
    await _eventsCol.doc(eventId).update({
      'title': title,
      'description': description,
      'eventType': eventType,
      'eventDateTime': Timestamp.fromDate(eventDateTime),
      'autoDeleteDateTime': Timestamp.fromDate(autoDeleteDateTime),
      'playlist': playlist,
    });
  }

  /// Elimina un evento (desactivación lógica)
  Future<void> deleteEvent(String eventId) async {
    await _eventsCol.doc(eventId).update({'isActive': false});
  }

  /// Limpia eventos expirados (opcional, para mantenimiento)
  Future<void> cleanupExpiredEvents() async {
    final now = Timestamp.now();
    final expiredEvents = await _eventsCol
        .where('autoDeleteDateTime', isLessThanOrEqualTo: now)
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in expiredEvents.docs) {
      await doc.reference.update({'isActive': false});
    }
  }
}
