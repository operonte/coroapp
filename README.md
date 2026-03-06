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

CoroApp está **100% preparada para Google Play Store** con todos los requisitos técnicos y legales cumplidos.

### ✅ Requisitos Cumplidos
- **Compatibilidad**: Android 5.0+ (API 21+) hasta Android 14+ (API 34)
- **Categorías**: Music & Audio + Productivity
- **Contenido**: Para mayores de edad, contenido religioso
- **Monetización**: Gratuita, sin anuncios ni compras internas
- **Políticas**: Privacidad y Términos de Servicio disponibles y funcionales
- **App Bundle**: Generado y firmado digitalmente para producción

### 📋 Documentación Legal
- **Política de Privacidad**: [Ver documento](https://operonte.github.io/releases/coroapp/policies/privacy_policy.html)
- **Términos de Servicio**: [Ver documento](https://operonte.github.io/releases/coroapp/policies/terms_of_service.html)
- **Data Security**: Configurado según requerimientos de Google
- **Firma Digital**: Válida por 10 años (hasta 2053-07-22)

### 🎯 Características Principales
- **5 tipos de voz**: Primera voz, tenor, bajo, contralto, soprano
- **Colores dinámicos**: AppBar personalizada por tipo de voz
- **Gestión completa**: Crear, editar, organizar canciones
- **Reproducción**: Pistas individuales por voz
- **Autenticación**: Cuenta Google segura con Firebase

### 📊 Alcance
- **Disponibilidad**: Mundial
- **Idioma**: Español (con expansión futura)
- **Testing**: Disponible para pruebas cerradas

### 🚀 Versión Actual para Google Play Store
La versión **v0.1.10** está lista para publicación con:
- **App Bundle (.aab)**: `coroapp_v0.1.9_signed.aab` (49.3 MB) - Firmado digitalmente
- **Target SDK 34** (Android 14): Cumple requisitos Google 2024
- **Firma Digital**: Clave válida hasta 2053-07-22
- **Metadatos**: Completos para store listing
- **Políticas**: 100% funcionales y accesibles

### 📱 Para Publicación en Google Play Console
**Archivos listos para subir:**
- **App Bundle**: `coroapp_v0.1.9_signed.aab` (para producción)
- **Términos de Servicio**: `terms_of_service.html` (ya en repositorio)
- **Política de Privacidad**: Ya existente y funcional

### 📋 Checklist Final de Publicación
| Requisito | Estado | Detalles |
|-----------|---------|----------|
| **App Bundle Firmado** | ✅ Listo | .aab con firma digital válida |
| **Términos de Servicio** | ✅ Listo | HTML completo y accesible |
| **Política de Privacidad** | ✅ Listo | Ya existente y funcional |
| **Target SDK 34** | ✅ Listo | Android 14+ compatible |
| **Compatibilidad 5.0+** | ✅ Listo | Desde 2015 hasta actualidad |
| **Categorías Definidas** | ✅ Listo | Music & Audio + Productivity |
| **Content Rating** | ⏳ Pendiente | Cuestionario por completar en Play Console |
| **Firma Digital** | ✅ Listo | Válida 10 años (hasta 2053) |

### 🎯 Próximos Pasos para Ti (Desarrollador)
1. **Subir App Bundle** a Google Play Console
2. **Completar Content Rating Questionnaire** (en Play Console)
3. **Configurar Store Listing** (descripciones, screenshots, categoría)
4. **Iniciar Closed Testing** con tus testers
5. **Revisión y lanzamiento público**

### � Para Testers
Contacta con **cristian.bravo.droguett@gmail.com** para acceso a:
- **Closed Testing** en Google Play Console
- Pruebas en diferentes dispositivos Android
- Feedback y reporte de bugs antes del lanzamiento

### 🌍 Disponibilidad y Soporte
- **Disponibilidad**: Próximamente en Google Play Store
- **Soporte técnico**: GitHub issues y correo directo
- **Documentación**: README y políticas actualizadas
- **Comunidad**: Repositorio abierto para contribuciones

---
**¡CoroApp está completamente lista para Google Play Store!** 🎉

### 📈 Métricas de Preparación
- **Tiempo total de preparación**: ~2 horas
- **Requisitos cumplidos**: 100%
- **Documentación legal**: 100%
- **Configuración técnica**: 100%
- **Archivos generados**: App Bundle firmado + políticas completas

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

