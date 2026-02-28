# CoroApp

Aplicación Flutter para organización de repertorio de coros cristianos, con:

- Autenticación con Google.
- Gestión de coros y tipos de voz (tenor, bajo, contralto, soprano).
- Listado de canciones filtradas por coro y voz.
- Reproducción de pistas individuales por voz (pendiente de mejorar el reproductor).

## Descarga de la APK

Puedes descargar la APK de release desde:

- [Descargar APK de CoroApp](https://github.com/operonte/coroapp/releases/download/v0.1.5/app-release.apk)

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

