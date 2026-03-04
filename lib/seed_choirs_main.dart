// Script para crear los 3 grupos en Firestore (base coroapp).
// Ejecutar desde la raíz del proyecto:
//   flutter run -t lib/seed_choirs_main.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.web,
  );

  final firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'coroapp',
  );

  const choirs = [
    {'id': 'grupo_evenezer', 'name': 'Evenezer', 'leaderPassword': 'david_vera_2026'},
    {'id': 'cuarteto_bendicion', 'name': 'Cuarteto Bendición', 'leaderPassword': 'david_vera_2026'},
    {'id': 'grupo_dogma', 'name': 'Grupo Dogma', 'leaderPassword': 'david_vera_2026'},
  ];

  for (final choir in choirs) {
    await firestore.collection('choirs').doc(choir['id'] as String).set({
      'name': choir['name'],
      'leaderPassword': choir['leaderPassword'],
    });
    print('Creado: ${choir['id']}');
  }

  print('Listo. Los 3 grupos están en Firestore (base coroapp).');
  exit(0);
}
