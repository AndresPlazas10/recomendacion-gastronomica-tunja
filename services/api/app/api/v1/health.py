from fastapi import APIRouter

from app.core.config import settings

router = APIRouter(tags=["salud"])


@router.get("/health")
def liveness() -> dict[str, str]:
    """Verificación de proceso vivo (no requiere autenticación)."""
    return {"status": "ok"}


@router.get("/v1/health")
def readiness() -> dict[str, str]:
    """Verificación de servicio y configuración."""
    return {
        "status": "ok",
        "servicio": "api",
        "env": settings.env,
        "supabase_configurado": str(bool(settings.supabase_url)).lower(),
    }
