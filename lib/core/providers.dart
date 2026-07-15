import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:just_audio/just_audio.dart';

import 'models/app_user.dart';
import 'models/choir.dart';
import 'models/song.dart';
import 'models/event.dart';
import 'repositories/auth_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/songs_repository.dart';
import 'repositories/events_repository.dart';
import 'repositories/choirs_repository.dart';

final globalAudioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(() {
    player.dispose();
  });
  return player;
});

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

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(ref.watch(firestoreProvider));
});

final choirsRepositoryProvider = Provider<ChoirsRepository>((ref) {
  return ChoirsRepository(ref.watch(firestoreProvider));
});

final choirsStreamProvider = StreamProvider<List<Choir>>((ref) {
  return ref.watch(choirsRepositoryProvider).watchChoirs();
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
    error: (_, _) => Stream<AppUser?>.value(null),
  );
});

final songsStreamProvider = StreamProvider.family<List<Song>, String>((ref, arg) {
  final parts = arg.split('|');
  final choirId = parts[0];
  final voice = parts[1];
  return ref.watch(songsRepositoryProvider).watchSongsForChoirAndVoice(
    choirId: choirId,
    voice: voice,
  );
});

final eventsStreamProvider = StreamProvider.family<List<Event>, String>((ref, choirId) {
  return ref.watch(eventsRepositoryProvider).watchEventsForChoir(choirId);
});

