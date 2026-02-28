import 'package:firebase_storage/firebase_storage.dart';

/// Resuelve URLs de Firebase Storage (gs://) a URLs de descarga firmadas.
/// Para URLs públicas (https://) las devuelve tal cual.
Future<String> resolveStorageUrl(String rawUrl) async {
  if (rawUrl.isEmpty) return rawUrl;
  if (!rawUrl.startsWith('gs://')) return rawUrl;

  final ref = FirebaseStorage.instance.refFromURL(rawUrl);
  return ref.getDownloadURL();
}
