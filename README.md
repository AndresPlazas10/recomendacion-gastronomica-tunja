# Recomendación gastronómica en Tunja

Aplicación móvil con IA para recomendar restaurantes de Tunja a partir de preferencias, ubicación e interacciones.

## Arquitectura

```
App móvil (React Native + Expo + TS)
        ↓ HTTPS (JWT)
FastAPI (Python) ──▶ Motor de recomendación (módulo Python)
        ↓ SQL
PostgreSQL / Supabase (RLS, PostGIS, pgvector)
```

- **Móvil:** `apps/mobile` (Expo SDK 57, Android 7+ / iOS 16.4+).
- **API:** `services/api` (FastAPI + Python 3.12).
- **ML:** `ml` (recomendador y experimentos).
- **Datos:** `supabase` (migraciones, RLS, seed).
- Arquitectura completa: `docs/README.md`.

## Estructura

```
apps/mobile/       App Expo + TypeScript
services/api/      FastAPI + pytest
ml/                Recomendador y experimentos
supabase/          Migraciones y seed
docs/              Índice de documentación
scripts/           Utilidades de desarrollo
```

## Requisitos

- Node.js 22 LTS y npm
- Python 3.12 y [uv](https://docs.astral.sh/uv/)
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- Docker (opcional, para Supabase local y builds)

## Inicio rápido

### 1. API

```bash
cd services/api
cp .env.example .env        # completar credenciales de Supabase
uv sync
uv run uvicorn app.main:app --reload
# http://localhost:8000/health
```

### 2. Móvil

```bash
cd apps/mobile
cp ../../.env.example .env  # completar EXPO_PUBLIC_*
npm install
npx expo start
```

### 3. Supabase

```bash
supabase start              # entorno local (o usar el proyecto dev en la nube)
supabase db reset           # aplica migraciones + seed
```

## Estado

- Sprint 0: base técnica y documentación realizadas; la bitácora mantiene pendiente reconciliar el cierre final.
- **Sprint 1 en cierre:** los cambios de HU-027/HU-001, eventos y privilegios RLS están publicados en `feat/sprint-1-close`; faltan CI, validaciones de Supabase, pruebas E2E del registro y builds Android/iOS para declarar el cierre.
- MVP: 186 SP en 6 sprints; el motor Python + pgvector llega en el Incremento 2.

## Convenciones

Ver `CONTRIBUTING.md`. Ramas cortas, Conventional Commits, CI verde obligatorio y sin secretos en el repositorio.
