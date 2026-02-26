import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/app_user.dart';
import 'repositories/auth_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/songs_repository.dart';

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  // Usar la base de datos no-default llamada "coroapp"
  return FirebaseFirestore.instanceFor(
    app: FirebaseFirestore.instance.app,
    databaseId: 'coroapp',
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
  );
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(firestoreProvider));
});

final songsRepositoryProvider = Provider<SongsRepository>((ref) {
  return SongsRepository(ref.watch(firestoreProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentAppUserProvider = StreamProvider<AppUser?>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return authAsync.when(
    data: (user) {
      if (user == null) {
        // Usuario no autenticado: emitimos null una vez.
        return Stream<AppUser?>.value(null);
      }
      return ref.watch(userRepositoryProvider).watchUser(user.uid);
    },
    // Mientras se resuelve el estado de auth, emitimos null una vez para que
    // la UI pueda avanzar (por ejemplo, mostrar la pantalla de login/perfil).
    loading: () => Stream<AppUser?>.value(null),
    // En caso de error, preferimos que la UI reciba null y pueda mostrar algo
    // manejable en lugar de quedarse bloqueada cargando para siempre.
    error: (_, __) => Stream<AppUser?>.value(null),
  );
});

