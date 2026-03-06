# CoroApp

Aplicación Flutter para organización de repertorio de coros cristianos, con:

- Autenticación con Google.
- Gestión de coros y tipos de voz (primera voz, tenor, bajo, contralto, soprano).
- Listado de canciones filtradas por coro y voz.
- Reproducción de pistas individuales por voz (pendiente de mejorar el reproductor).

## Descarga de la APK

Puedes descargar la APK más reciente desde:

- [Descargar CoroApp v0.1.8 (Última versión)](https://github.com/operonte/coroapp/releases/download/v0.1.8/coroapp_v0.1.8_colores_corregidos.apk)

### Versiones Anteriores
- [v0.1.7 - 5 Voces + Colores Dinámicos](https://github.com/operonte/coroapp/releases/download/v0.1.7/coroapp_v0.1.7_5voces_colores.apk)
- [v0.1.6 - Edición de Canciones](https://github.com/operonte/coroapp/releases/download/v0.1.6/coroapp_v0.1.6_final.apk)

## Firebase Storage: reglas y formato de URLs

Para que los PDFs y audios se carguen correctamente, las **reglas de Firebase Storage** deben permitir lectura a usuarios autenticados:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

Las URLs en Firestore (`lyricsUrl`, `audioUrls`) pueden ser:
- **gs://** – ej: `gs://coroapp-e8122.firebasestorage.app/coroapp/choirs/coro_central_001/songs/alabanza_total_001/letra.pdf`
- **Ruta relativa** – ej: `coroapp/choirs/coro_central_001/songs/alabanza_total_001/letra.pdf`
- **https://** – URL pública directa (se abre sin resolver)

Asegúrate de que el archivo exista en Storage en la ruta indicada.

## Crear grupos (coros)

Para añadir los grupos **grupo_evenezer**, **cuarteto_bendicion** y **grupo_dogma** en Firestore:

```bash
flutter run -t lib/seed_choirs_main.dart
```

(O manualmente según [docs/choirs_seed.md](docs/choirs_seed.md).)

## Configuración de jefe de grupo

Para que los miembros puedan convertirse en jefe de grupo, añade el campo `leaderPassword` al documento del coro en Firestore (colección `choirs`):

```
choirs/coro_central_001
  name: "Coro Central"
  leaderPassword: "david_vera_2026"  # o la contraseña que definas
```

## Política de privacidad

La política de privacidad de CoroApp está disponible en:

- [Política de privacidad de CoroApp](PRIVACY.md)

