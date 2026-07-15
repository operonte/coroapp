import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_url_service.dart';
import '../models/song.dart';

class OfflineAudioNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    return {};
  }

  bool isDownloaded(String songId, String voice) {
    final key = _cacheKey(songId, voice);
    return state[key] ?? false;
  }

  String _cacheKey(String songId, String voice) => '${songId}_$voice';

  Future<String> _getLocalPath(String songId, String voice) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/cached_audio');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return '${cacheDir.path}/${songId}_$voice.mp3';
  }

  Future<void> checkStatus(String songId, String voice) async {
    final path = await _getLocalPath(songId, voice);
    final file = File(path);
    final exists = await file.exists();
    final key = _cacheKey(songId, voice);
    if (state[key] != exists) {
      state = {
        ...state,
        key: exists,
      };
    }
  }

  Future<String?> getLocalFilePathIfCached(String songId, String voice) async {
    final path = await _getLocalPath(songId, voice);
    final file = File(path);
    if (await file.exists()) {
      return path;
    }
    return null;
  }

  Future<void> downloadAudio({
    required Song song,
    required String voice,
    required ValueChanged<double>? onProgress,
  }) async {
    final gsUrl = song.audioUrls[voice];
    if (gsUrl == null || gsUrl.isEmpty) return;

    try {
      final remoteUrl = await resolveStorageUrl(gsUrl);
      final localPath = await _getLocalPath(song.id, voice);
      
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(remoteUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final file = File(localPath);
        final sink = file.openWrite();
        
        final totalBytes = response.contentLength;
        int downloadedBytes = 0;

        await response.listen(
          (chunk) {
            sink.add(chunk);
            downloadedBytes += chunk.length;
            if (totalBytes > 0 && onProgress != null) {
              onProgress(downloadedBytes / totalBytes);
            }
          },
          onDone: () async {
            await sink.close();
            state = {
              ...state,
              _cacheKey(song.id, voice): true,
            };
          },
          onError: (e) async {
            await sink.close();
            if (await file.exists()) {
              await file.delete();
            }
          },
          cancelOnError: true,
        ).asFuture();
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading audio: $e');
      rethrow;
    }
  }

  Future<void> deleteAudio(String songId, String voice) async {
    try {
      final path = await _getLocalPath(songId, voice);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      state = {
        ...state,
        _cacheKey(songId, voice): false,
      };
    } catch (e) {
      debugPrint('Error deleting audio: $e');
    }
  }

  bool isPdfDownloaded(String songId) {
    return state['pdf_$songId'] ?? false;
  }

  Future<String> _getLocalPdfPath(String songId) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/cached_lyrics');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return '${cacheDir.path}/$songId.pdf';
  }

  Future<void> checkPdfStatus(String songId) async {
    final path = await _getLocalPdfPath(songId);
    final file = File(path);
    final exists = await file.exists();
    final key = 'pdf_$songId';
    if (state[key] != exists) {
      state = {
        ...state,
        key: exists,
      };
    }
  }

  Future<String?> getLocalPdfPathIfCached(String songId) async {
    final path = await _getLocalPdfPath(songId);
    final file = File(path);
    if (await file.exists()) {
      return path;
    }
    return null;
  }

  Future<void> downloadPdf({
    required Song song,
    required ValueChanged<double>? onProgress,
  }) async {
    final gsUrl = song.lyricsUrl;
    if (gsUrl == null || gsUrl.isEmpty) return;

    try {
      final remoteUrl = await resolveStorageUrl(gsUrl);
      final localPath = await _getLocalPdfPath(song.id);
      
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(remoteUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final file = File(localPath);
        final sink = file.openWrite();
        
        final totalBytes = response.contentLength;
        int downloadedBytes = 0;

        await response.listen(
          (chunk) {
            sink.add(chunk);
            downloadedBytes += chunk.length;
            if (totalBytes > 0 && onProgress != null) {
              onProgress(downloadedBytes / totalBytes);
            }
          },
          onDone: () async {
            await sink.close();
            state = {
              ...state,
              'pdf_${song.id}': true,
            };
          },
          onError: (e) async {
            await sink.close();
            if (await file.exists()) {
              await file.delete();
            }
          },
          cancelOnError: true,
        ).asFuture();
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      rethrow;
    }
  }

  Future<void> deletePdf(String songId) async {
    try {
      final path = await _getLocalPdfPath(songId);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      state = {
        ...state,
        'pdf_$songId': false,
      };
    } catch (e) {
      debugPrint('Error deleting PDF: $e');
    }
  }
}

final offlineAudioProvider = NotifierProvider<OfflineAudioNotifier, Map<String, bool>>(() {
  return OfflineAudioNotifier();
});
