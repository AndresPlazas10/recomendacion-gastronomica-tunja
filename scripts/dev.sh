#!/usr/bin/env bash
# Levanta la API y la app móvil en terminales separadas (macOS/Linux con tmux opcional).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v tmux >/dev/null 2>&1; then
  tmux new-session -d -s app -n api "cd '$ROOT/services/api' && uv run uvicorn app.main:app --reload"
  tmux new-window -t app -n mobile "cd '$ROOT/apps/mobile' && npx expo start"
  tmux attach -t app
else
  echo "Levantando API (Ctrl+C para detener)..."
  (cd "$ROOT/services/api" && uv run uvicorn app.main:app --reload) &
  echo "Levantando Expo..."
  (cd "$ROOT/apps/mobile" && npx expo start)
fi
