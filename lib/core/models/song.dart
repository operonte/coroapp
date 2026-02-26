class Song {
  Song({
    required this.id,
    required this.choirId,
    required this.title,
    this.author,
    this.tone,
    required this.voicesAvailable,
    required this.audioUrls,
    this.lyricsUrl,
    this.demoVideoUrl,
  });

  final String id;
  final String choirId;
  final String title;
  final String? author;
  final String? tone;
  final List<String> voicesAvailable;
  final Map<String, String> audioUrls;
  final String? lyricsUrl;
  final String? demoVideoUrl;

  factory Song.fromMap(String id, Map<String, dynamic> data) {
    return Song(
      id: id,
      choirId: data['choirId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      author: data['author'] as String?,
      tone: data['tone'] as String?,
      voicesAvailable: List<String>.from(data['voicesAvailable'] ?? []),
      audioUrls: Map<String, String>.from(
        (data['audioUrls'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as String)),
      ),
      lyricsUrl: data['lyricsUrl'] as String?,
      demoVideoUrl: data['demoVideoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'choirId': choirId,
      'title': title,
      'author': author,
      'tone': tone,
      'voicesAvailable': voicesAvailable,
      'audioUrls': audioUrls,
      'lyricsUrl': lyricsUrl,
      'demoVideoUrl': demoVideoUrl,
    };
  }
}

