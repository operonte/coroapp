# Grupos (coros) a crear en Firestore

## Opción 1: Por CLI (recomendado)

Desde la raíz del proyecto, ejecuta:

```bash
flutter run -t lib/seed_choirs_main.dart
```

El script crea los 3 documentos en la base de datos **coroapp**. Asegúrate de que esa base de datos exista en Firebase Console (Firestore → Crear base de datos → ID `coroapp`).

---

## Opción 2: Manual en Firebase Console

En la base de datos **coroapp** (no la default), colección `choirs`, crea estos tres documentos (o añade los campos si el documento ya existe):

---

## 1. grupo_evenezer

| Campo | Tipo | Valor |
|-------|------|--------|
| `name` | string | Evenezer |
| `leaderPassword` | string | david_vera_2026 |

**ID del documento:** `grupo_evenezer`

---

## 2. cuarteto_bendicion

| Campo | Tipo | Valor |
|-------|------|--------|
| `name` | string | Cuarteto Bendición |
| `leaderPassword` | string | david_vera_2026 |

**ID del documento:** `cuarteto_bendicion`

---

## 3. grupo_dogma

| Campo | Tipo | Valor |
|-------|------|--------|
| `name` | string | Grupo Dogma |
| `leaderPassword` | string | david_vera_2026 |

**ID del documento:** `grupo_dogma`

---

## Cómo añadirlos en Firebase Console

1. Abre [Firebase Console](https://console.firebase.google.com) → tu proyecto → Firestore.
2. Si usas la base de datos por defecto, crea o cambia a la base de datos **coroapp** (la app usa `databaseId: 'coroapp'`).
3. En la colección `choirs`, crea un documento con el **ID** indicado arriba y los campos `name` y `leaderPassword`.

Con esto los usuarios podrán elegir ese coro en su perfil y los jefes podrán usar la contraseña `david_vera_2026` para obtener derechos de jefe de grupo.
