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
}

