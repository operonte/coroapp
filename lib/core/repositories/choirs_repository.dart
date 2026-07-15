import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/choir.dart';

class ChoirsRepository {
  ChoirsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _choirsCol =>
      _firestore.collection('choirs');

  Future<List<Choir>> getChoirs() async {
    final snap = await _choirsCol.get();
    return snap.docs.map((doc) => Choir.fromMap(doc.id, doc.data())).toList();
  }

  Stream<List<Choir>> watchChoirs() {
    return _choirsCol.snapshots().map((snap) =>
        snap.docs.map((doc) => Choir.fromMap(doc.id, doc.data())).toList());
  }
}
