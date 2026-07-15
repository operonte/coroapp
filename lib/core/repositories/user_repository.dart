import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  Future<AppUser?> getUser(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  Future<void> upsertUserFromFirebaseUser({
    required String uid,
    required String displayName,
    required String email,
    String? photoUrl,
  }) async {
    final docRef = _usersCol.doc(uid);
    final existing = await docRef.get();
    final data = <String, dynamic>{
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
    };

    if (!existing.exists) {
      await docRef.set({
        ...data,
        'role': 'miembro',
      });
    } else {
      await docRef.update(data);
    }
  }

  Stream<AppUser?> watchUser(String uid) {
    return _usersCol.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(doc.id, doc.data()!);
    });
  }

  Future<void> updateProfile({
    required String uid,
    required String choirId,
    required String voice,
  }) async {
    await _usersCol.doc(uid).update({
      'choirId': choirId,
      'voice': voice,
    });
  }
}

