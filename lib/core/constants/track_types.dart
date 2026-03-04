// Tipos de pista: voces, instrumentos y demo.
// Las voces e instrumentos solo se muestran si la canción los usa.
// La pista "demo" siempre se muestra (para fomentar completarla).

/// Claves de las 4 voces.
const List<String> kVoiceTrackKeys = [
  'tenor',
  'bajo',
  'contralto',
  'soprano',
];

/// Claves de instrumentos / pistas adicionales (bajo_instrumental para no chocar con la voz "bajo").
const List<String> kInstrumentTrackKeys = [
  'bateria',
  'guitarra',
  'bajo_instrumental',
  'teclado',
  'primera_voz',
];

/// Clave de la pista demo. Siempre visible.
const String kDemoTrackKey = 'demo';

/// Todas las claves de pista (voces + instrumentos + demo).
List<String> get allTrackKeys => [
  ...kVoiceTrackKeys,
  ...kInstrumentTrackKeys,
  kDemoTrackKey,
];

/// Etiqueta visible para cada clave de pista.
String trackKeyToLabel(String key) {
  switch (key) {
    case 'tenor':
      return 'Tenor';
    case 'bajo':
      return 'Bajo';
    case 'contralto':
      return 'Contralto';
    case 'soprano':
      return 'Soprano';
    case 'bateria':
      return 'Batería';
    case 'guitarra':
      return 'Guitarra';
    case 'bajo_instrumental':
      return 'Bajo (instrumento)';
    case 'teclado':
      return 'Teclado';
    case 'primera_voz':
      return 'Primera voz';
    case 'demo':
      return 'Demo';
    default:
      return key;
  }
}

/// Extensiones permitidas para pistas de audio/video.
const List<String> kAudioVideoExtensions = ['mp3', 'mp4', 'wav', 'mpeg'];

/// Extensión permitida para letra.
const String kLyricsExtension = 'pdf';
