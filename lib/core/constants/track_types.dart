import 'package:flutter/material.dart';

// Tipos de pista: voces, instrumentos y demo.
// Las voces e instrumentos solo se muestran si la canción los usa.
// La pista "demo" siempre se muestra (para fomentar completarla).

/// Claves de las 5 voces.
const List<String> kVoiceTrackKeys = [
  'primera_voz',
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
    case 'primera_voz':
      return 'Primera voz';
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
    case 'demo':
      return 'Demo';
    default:
      return key;
  }
}

/// Color de AppBar para cada tipo de voz.
Color getAppBarColor(String voice) {
  switch (voice) {
    case 'primera_voz':
      return const Color(0xFF00BCD4); // Cyan/Azul claro (diferente al tenor)
    case 'tenor':
      return const Color(0xFF2196F3); // Azul original de la app
    case 'bajo':
      return const Color(0xFF795548); // Café
    case 'contralto':
      return const Color(0xFFCE93D8); // Morado claro
    case 'soprano':
      return const Color(0xFFF48FB1); // Rosado
    default:
      return const Color(0xFF2196F3); // Azul por defecto
  }
}

/// Extensiones permitidas para pistas de audio/video.
const List<String> kAudioVideoExtensions = ['mp3', 'mp4', 'wav', 'mpeg'];

/// Extensión permitida para letra.
const String kLyricsExtension = 'pdf';
