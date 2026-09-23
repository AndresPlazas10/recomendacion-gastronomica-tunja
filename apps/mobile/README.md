# App móvil (Expo + TypeScript)

Cliente móvil Android/iOS. Expo SDK 57 (Android 7+ / iOS 16.4+).

## Inicio

```bash
cp ../../.env.example .env    # completar EXPO_PUBLIC_*
npm install
npx expo start
```

- `a` abre Android, `i` abre iOS.
- La pantalla inicial verifica `GET /health` de la API.

## Calidad

```bash
npx tsc --noEmit
npx eslint .
npx expo-doctor
```

## Estructura

```
app/            rutas (Expo Router)
src/lib/        supabase, env, utilidades
```

## Notas

- Los tokens de sesión se guardan con `expo-secure-store`.
- La ubicación se solicitará con `expo-location` solo al usarla (Sprint 2+).
- La captura de eventos usa `POST /v1/eventos` (regla transversal desde S1).
