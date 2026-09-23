# Guía de contribución

## Ramas

- `main` está protegido: no se hace push directo.
- Ramas cortas desde `main`:
  - `feat/<descripcion>` — nueva funcionalidad
  - `fix/<descripcion>` — corrección
  - `docs/<descripcion>` — documentación
  - `chore/<descripcion>` — mantenimiento

## Commits

Conventional Commits en español o inglés, consistentes:

```
feat(api): endpoint de registro de usuario
fix(mobile): validación de correo en el formulario
docs: actualizar contrato de API
test(api): pruebas de RLS por rol
```

## Pull requests

1. CI verde (lint + pruebas).
2. Al menos 1 revisión.
3. Squash merge a `main`.
4. Descripción con: qué cambia, cómo probarlo y referencia a la HU.

## Calidad

- **API:** Ruff (`uv run ruff check .` y `uv run ruff format .`), pytest.
- **Móvil:** TypeScript strict, ESLint, Prettier.
- **Datos:** migraciones versionadas; nunca editar una migración ya aplicada.

## Seguridad

- No commitear secretos ni `.env` (solo `.env.example`).
- No incluir datos personales reales en pruebas, seeds ni capturas.
- La `service_role` de Supabase solo se usa en el backend.
