# API (FastAPI)

API de negocio y frontera con el motor de recomendación.

## Requisitos

- Python 3.12
- [uv](https://docs.astral.sh/uv/)

## Inicio

```bash
cp .env.example .env    # completar credenciales
uv sync --extra dev
uv run uvicorn app.main:app --reload
```

- `GET /health` → liveness
- `GET /v1/health` → readiness
- Documentación interactiva: `http://localhost:8000/docs` (solo en desarrollo)

## Calidad

```bash
uv run ruff check .
uv run ruff format --check .
uv run pytest -q
```

## Estructura

```
app/
├── main.py          # aplicación FastAPI
├── core/config.py   # configuración por entorno
└── api/v1/          # routers (health, …)
tests/               # pruebas
```

El contrato completo está en la documentación de planificación (`docs/README.md`).
