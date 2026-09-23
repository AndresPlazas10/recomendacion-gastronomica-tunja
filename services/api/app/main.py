from fastapi import FastAPI

from app.api.v1.health import router as health_router
from app.core.config import settings

app = FastAPI(
    title="API de recomendación gastronómica",
    version="0.1.0",
    description="Frontera de servicio entre la app móvil y los datos/recomendador.",
)

app.include_router(health_router)

if settings.env == "development":
    @app.get("/", include_in_schema=False)
    def root() -> dict[str, str]:
        return {"servicio": "api", "docs": "/docs"}
