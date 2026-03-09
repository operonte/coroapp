import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/song.dart';

class SongsRepository {
  SongsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _songsCol =>
      _firestore.collection('songs');

  Stream<List<Song>> watchSongsForChoirAndVoice({
    required String choirId,
    required String voice,
  }) {
    return _songsCol
        .where('choirId', isEqualTo: choirId)
        .where('voicesAvailable', arrayContains: voice)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Song.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Stream<List<Song>> watchAllSongsForChoir(String choirId) {
    return _songsCol
        .where('choirId', isEqualTo: choirId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Song.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// Genera un ID libre para una nueva canción (para usar en rutas de Storage).
  String generateSongId() => _songsCol.doc().id;

  /// Crea un documento de canción en Firestore.
  Future<void> createSong({
    required String songId,
    required String choirId,
    required String title,
    String? author,
    String? tone,
    required List<String> voicesAvailable,
    required Map<String, String> audioUrls,
    String? lyricsUrl,
    String? demoVideoUrl,
  }) async {
    await _songsCol.doc(songId).set({
      'choirId': choirId,
      'title': title,
      'author': author,
      'tone': tone,
      'voicesAvailable': voicesAvailable,
      'audioUrls': audioUrls,
      'lyricsUrl': lyricsUrl,
      'demoVideoUrl': demoVideoUrl,
    });
  }

  /// Actualiza una canción existente en Firestore.
  Future<void> updateSong({
    required String songId,
    required String title,
    String? author,
    String? tone,
    required List<String> voicesAvailable,
    required Map<String, String> audioUrls,
    String? lyricsUrl,
    String? demoVideoUrl,
  }) async {
    await _songsCol.doc(songId).update({
      'title': title,
      'author': author,
      'tone': tone,
      'voicesAvailable': voicesAvailable,
      'audioUrls': audioUrls,
      'lyricsUrl': lyricsUrl,
      'demoVideoUrl': demoVideoUrl,
    });
  }

  /// Elimina una canción de Firestore.
  Future<void> deleteSong(String songId) async {
    await _songsCol.doc(songId).delete();
  }
}

