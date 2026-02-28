# CoroApp

Aplicación Flutter para organización de repertorio de coros cristianos, con:

- Autenticación con Google.
- Gestión de coros y tipos de voz (tenor, bajo, contralto, soprano).
- Listado de canciones filtradas por coro y voz.
- Reproducción de pistas individuales por voz (pendiente de mejorar el reproductor).

## Descarga de la APK

Puedes descargar la APK de release desde:

- [Descargar APK de CoroApp](https://github.com/operonte/coroapp/releases/download/v0.1.4/app-release.apk)

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

