# App móvil (Expo + TypeScript)

Cliente móvil Android/iOS. Expo SDK 57 (Android 7+ / iOS 16.4+).

## Inicio

```bash
cp ../../.env.example .env    # completar EXPO_PUBLIC_*
npm install
npx expo start
```

- `a` abre Android, `i` abre iOS.
- La pantalla inicial permite crear una cuenta con Supabase Auth y verificar `GET /health`.

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
- `src/lib/events.ts` centraliza el envío autenticado de eventos a `POST /v1/eventos`.
- El registro de eventos requiere consentimiento vigente de interacciones.
