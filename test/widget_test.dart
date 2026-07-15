import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coroapp/core/models/app_user.dart';
import 'package:coroapp/core/models/choir.dart';
import 'package:coroapp/core/models/song.dart';
import 'package:coroapp/core/models/event.dart';
import 'package:coroapp/core/services/offline_audio_service.dart';

void main() {
  group('AppUser Model Tests', () {
    test('fromMap should parse correctly with valid data', () {
      final data = {
        'displayName': 'Juan Perez',
        'email': 'juan@example.com',
        'photoUrl': 'https://example.com/photo.jpg',
        'role': 'admin_coro',
        'choirId': 'coro_central_001',
        'voice': 'tenor',
      };

      final user = AppUser.fromMap('user_123', data);

      expect(user.id, 'user_123');
      expect(user.displayName, 'Juan Perez');
      expect(user.email, 'juan@example.com');
      expect(user.photoUrl, 'https://example.com/photo.jpg');
      expect(user.role, 'admin_coro');
      expect(user.choirId, 'coro_central_001');
      expect(user.voice, 'tenor');
      expect(user.hasCompletedProfile, true);
    });

    test('toMap should return correct map', () {
      final user = AppUser(
        id: 'user_123',
        displayName: 'Juan Perez',
        email: 'juan@example.com',
        photoUrl: 'https://example.com/photo.jpg',
        role: 'admin_coro',
        choirId: 'coro_central_001',
        voice: 'tenor',
      );

      final map = user.toMap();

      expect(map['displayName'], 'Juan Perez');
      expect(map['email'], 'juan@example.com');
      expect(map['photoUrl'], 'https://example.com/photo.jpg');
      expect(map['role'], 'admin_coro');
      expect(map['choirId'], 'coro_central_001');
      expect(map['voice'], 'tenor');
    });
  });

  group('Choir Model Tests', () {
    test('fromMap and toMap should serialize correctly', () {
      final data = {
        'name': 'Coro Central',
        'description': 'Coro principal de la congregacion',
        'leaderPassword': 'secret_password_123',
      };

      final choir = Choir.fromMap('choir_001', data);

      expect(choir.id, 'choir_001');
      expect(choir.name, 'Coro Central');
      expect(choir.description, 'Coro principal de la congregacion');
      expect(choir.leaderPassword, 'secret_password_123');

      final map = choir.toMap();
      expect(map['name'], 'Coro Central');
      expect(map['description'], 'Coro principal de la congregacion');
      expect(map['leaderPassword'], 'secret_password_123');
    });
  });

  group('Song Model Tests', () {
    test('fromMap and toMap should serialize correctly', () {
      final data = {
        'choirId': 'choir_001',
        'title': 'Cuan Grande Es El',
        'author': 'Stuart K. Hine',
        'tone': 'A#',
        'voicesAvailable': ['tenor', 'bajo'],
        'audioUrls': {
          'tenor': 'gs://bucket/tenor.mp3',
          'bajo': 'gs://bucket/bajo.mp3',
        },
        'lyricsUrl': 'gs://bucket/lyrics.pdf',
        'demoVideoUrl': 'https://youtube.com/demo',
      };

      final song = Song.fromMap('song_001', data);

      expect(song.id, 'song_001');
      expect(song.choirId, 'choir_001');
      expect(song.title, 'Cuan Grande Es El');
      expect(song.author, 'Stuart K. Hine');
      expect(song.tone, 'A#');
      expect(song.voicesAvailable, containsAll(['tenor', 'bajo']));
      expect(song.audioUrls['tenor'], 'gs://bucket/tenor.mp3');
      expect(song.lyricsUrl, 'gs://bucket/lyrics.pdf');
      expect(song.demoVideoUrl, 'https://youtube.com/demo');

      final map = song.toMap();
      expect(map['title'], 'Cuan Grande Es El');
      expect(map['author'], 'Stuart K. Hine');
      expect(map['voicesAvailable'], containsAll(['tenor', 'bajo']));
      expect(map['audioUrls'], containsPair('tenor', 'gs://bucket/tenor.mp3'));
    });
  });

  group('Event Model Tests', () {
    test('fromMap and toMap should serialize correctly', () {
      final now = DateTime.now();
      final eventTime = now.add(const Duration(days: 2));
      final deleteTime = now.add(const Duration(days: 10));

      final data = {
        'choirId': 'choir_001',
        'title': 'Ensayo General Sabado',
        'description': 'Ensayo de voces y ensamble',
        'eventType': 'ensayo',
        'eventDateTime': Timestamp.fromDate(eventTime),
        'autoDeleteDateTime': Timestamp.fromDate(deleteTime),
        'createdBy': 'user_123',
        'createdAt': Timestamp.fromDate(now),
        'isActive': true,
        'playlist': ['song_001', 'song_002'],
      };

      final event = Event.fromMap('event_001', data);

      expect(event.id, 'event_001');
      expect(event.choirId, 'choir_001');
      expect(event.title, 'Ensayo General Sabado');
      expect(event.eventTypeLabel, 'Ensayo');
      expect(event.hasPlaylist, true);
      expect(event.playlist, containsAll(['song_001', 'song_002']));
      expect(event.isActive, true);

      final map = event.toMap();
      expect(map['title'], 'Ensayo General Sabado');
      expect(map['eventType'], 'ensayo');
      expect(map['isActive'], true);
      expect(map['playlist'], containsAll(['song_001', 'song_002']));
    });
  });

  group('OfflineAudioNotifier Tests', () {
    test('should initialize with empty state and resolve defaults correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(offlineAudioProvider.notifier);
      expect(notifier.state, isEmpty);
      expect(notifier.isDownloaded('song_abc', 'soprano'), false);
      expect(notifier.isPdfDownloaded('song_abc'), false);
    });
  });
}
