import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String choirId;
  final String title;
  final String description;
  final String eventType; // 'ensayo', 'presentacion', 'reunion'
  final DateTime eventDateTime;
  final DateTime autoDeleteDateTime;
  final String createdBy;
  final DateTime createdAt;
  final bool isActive;
  final List<String> playlist; // Array de songIds

  Event({
    required this.id,
    required this.choirId,
    required this.title,
    required this.description,
    required this.eventType,
    required this.eventDateTime,
    required this.autoDeleteDateTime,
    required this.createdBy,
    required this.createdAt,
    required this.isActive,
    required this.playlist,
  });

  factory Event.fromMap(String id, Map<String, dynamic> data) {
    return Event(
      id: id,
      choirId: data['choirId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      eventType: data['eventType'] ?? '',
      eventDateTime: (data['eventDateTime'] as Timestamp).toDate(),
      autoDeleteDateTime: (data['autoDeleteDateTime'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      playlist: List<String>.from(data['playlist'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'choirId': choirId,
      'title': title,
      'description': description,
      'eventType': eventType,
      'eventDateTime': Timestamp.fromDate(eventDateTime),
      'autoDeleteDateTime': Timestamp.fromDate(autoDeleteDateTime),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'playlist': playlist,
    };
  }

  String get eventTypeLabel {
    switch (eventType) {
      case 'ensayo':
        return 'Ensayo';
      case 'presentacion':
        return 'Presentación';
      case 'reunion':
        return 'Reunión';
      default:
        return eventType;
    }
  }

  bool get hasPlaylist => playlist.isNotEmpty;
}
