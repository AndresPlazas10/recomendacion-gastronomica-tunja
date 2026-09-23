#!/usr/bin/env bash
# Ejecuta las verificaciones locales (lint + pruebas) de API y móvil.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "== API =="
if command -v uv >/dev/null 2>&1; then
  (cd "$ROOT/services/api" && uv run ruff check . && uv run pytest -q)
else
  echo "uv no está instalado; se omite la verificación de API"
fi

echo "== Móvil =="
if [ -d "$ROOT/apps/mobile/node_modules" ]; then
  (cd "$ROOT/apps/mobile" && npx tsc --noEmit && npx eslint .)
else
  echo "node_modules no existe; ejecuta 'npm install' en apps/mobile"
fi

echo "OK"
