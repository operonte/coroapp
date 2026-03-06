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

## 📱 Google Play Store

CoroApp está preparada para publicación en Google Play Store con:

### ✅ Requisitos Cumplidos
- **Compatibilidad**: Android 5.0+ (API 21+) hasta Android 14 (API 34)
- **Categorías**: Music & Audio + Productivity
- **Contenido**: Para mayores de edad, contenido religioso
- **Monetización**: Gratuita, sin anuncios ni compras internas
- **Políticas**: Privacidad y Términos de Servicio disponibles

### 📋 Documentación Legal
- **Política de Privacidad**: [Ver documento](https://operonte.github.io/releases/coroapp/policies/privacy_policy.html)
- **Términos de Servicio**: [Ver documento](https://operonte.github.io/releases/coroapp/policies/terms_of_service.html)
- **Data Security**: Configurado según requerimientos de Google

### 🎯 Características Principales
- **5 tipos de voz**: Primera voz, tenor, bajo, contralto, soprano
- **Colores dinámicos**: AppBar personalizada por tipo de voz
- **Gestión completa**: Crear, editar, organizar canciones
- **Reproducción**: Pistas individuales por voz
- **Autenticación**: Cuenta Google segura

### 📊 Alcance
- **Disponibilidad**: Mundial
- **Idiomas**: Español (con expansión futura)
- **Testing**: Disponible para pruebas cerradas

### 🚀 Próxima Versión
La versión **v0.1.9** está preparada para Google Play Store con:
- **App Bundle (.aab)** optimizado para Play Store
- **Target SDK 34** (Android 14) cumplimiento 2024
- **Firma digital**: Lista para producción
- **Metadatos completos**: Content rating y seguridad

### 📱 Para Testers
Contacta con **cristian.bravo.droguett@gmail.com** para acceso a:
- **Closed Testing** (pruebas controladas)
- **Feedback y reporte de bugs**
- **Validación previa al lanzamiento

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

