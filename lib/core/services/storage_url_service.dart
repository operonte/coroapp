import 'package:firebase_storage/firebase_storage.dart';

/// Resuelve URLs de Firebase Storage a URLs de descarga firmadas.
/// Acepta: gs://bucket/path, https:// (devuelve tal cual), o path relativo (usa bucket por defecto).
Future<String> resolveStorageUrl(String rawUrl) async {
  if (rawUrl.isEmpty) return rawUrl;

  // URLs públicas: devolver tal cual
  if (rawUrl.startsWith('https://') || rawUrl.startsWith('http://')) {
    return rawUrl;
  }

  Reference ref;
  if (rawUrl.startsWith('gs://')) {
    ref = FirebaseStorage.instance.refFromURL(rawUrl);
  } else {
    // Path relativo (ej: coroapp/choirs/.../letra.pdf) - usar ref con bucket por defecto
    ref = FirebaseStorage.instance.ref(rawUrl);
  }
  return ref.getDownloadURL();
}
