from datetime import UTC, datetime
from typing import Any, Literal
from uuid import UUID

import httpx
from fastapi import APIRouter, Header, HTTPException, status
from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.core.config import settings

router = APIRouter(prefix="/v1/eventos", tags=["eventos"])

TipoEvento = Literal[
    "busqueda",
    "ver_restaurante",
    "ver_plato",
    "recomendacion_impresion",
    "clic_recomendacion",
]
TipoEntidad = Literal["restaurante", "plato", "consulta"]
OrigenEvento = Literal["busqueda", "recomendacion", "catalogo"]


class EventoEntrada(BaseModel):
    model_config = ConfigDict(extra="forbid")

    tipo: TipoEvento
    entidad_tipo: TipoEntidad
    entidad_id: UUID | None = None
    origen: OrigenEvento | None = None
    sesion_id: UUID
    termino: str | None = Field(default=None, max_length=500)
    filtros: dict[str, Any] | None = None
    recomendacion_id: UUID | None = None
    request_id: UUID | None = None
    modelo_version: str | None = Field(default=None, max_length=100)
    posicion: int | None = Field(default=None, ge=1, le=32767)
    creado_en: datetime | None = None

    @model_validator(mode="after")
    def validar_entidad_y_atribucion(self) -> "EventoEntrada":
        entidad_esperada = {
            "busqueda": "consulta",
            "ver_restaurante": "restaurante",
            "ver_plato": "plato",
            "recomendacion_impresion": "restaurante",
            "clic_recomendacion": "restaurante",
        }[self.tipo]
        if self.entidad_tipo != entidad_esperada:
            raise ValueError("El tipo de entidad no corresponde al tipo de evento.")
        if self.tipo != "busqueda" and self.entidad_id is None:
            raise ValueError("Este evento requiere entidad_id.")
        if self.tipo in {"recomendacion_impresion", "clic_recomendacion"}:
            datos_atribucion = (
                self.recomendacion_id,
                self.request_id,
                self.modelo_version,
                self.posicion,
            )
            if not all(datos_atribucion):
                raise ValueError("El evento de recomendación requiere sus datos de atribución.")
        return self


class LoteEventos(BaseModel):
    model_config = ConfigDict(extra="forbid")

    eventos: list[EventoEntrada] = Field(min_length=1, max_length=50)


def _supabase_headers(*, token: str | None = None, service_role: bool = False) -> dict[str, str]:
    if not settings.supabase_url or not settings.supabase_anon_key:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="El servicio de autenticación no está configurado.",
        )
    key = settings.supabase_service_role_key if service_role else settings.supabase_anon_key
    if not key:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="El servicio de eventos no está configurado.",
        )
    headers = {"apikey": key}
    if service_role:
        headers["Authorization"] = f"Bearer {key}"
    elif token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def autenticar_usuario(token: str) -> UUID:
    headers = _supabase_headers(token=token)
    try:
        response = httpx.get(
            f"{settings.supabase_url.rstrip('/')}/auth/v1/user",
            headers=headers,
            timeout=5.0,
        )
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="No fue posible validar la sesión.",
        ) from exc

    if response.status_code in {401, 403}:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Sesión inválida.")
    if response.status_code != 200:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="No fue posible validar la sesión.",
        )
    try:
        return UUID(response.json()["id"])
    except (KeyError, TypeError, ValueError) as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesión inválida.",
        ) from exc


def verificar_consentimiento(usuario_id: UUID) -> None:
    headers = _supabase_headers(service_role=True)
    params = {
        "select": "otorgado",
        "usuario_id": f"eq.{usuario_id}",
        "tipo": "eq.interacciones",
        "order": "fecha.desc",
        "limit": "1",
    }
    try:
        response = httpx.get(
            f"{settings.supabase_url.rstrip('/')}/rest/v1/consentimientos",
            headers=headers,
            params=params,
            timeout=5.0,
        )
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="No fue posible verificar el consentimiento.",
        ) from exc

    if response.status_code != 200:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="No fue posible verificar el consentimiento.",
        )
    consentimientos = response.json()
    if not consentimientos or consentimientos[0].get("otorgado") is not True:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Se requiere consentimiento vigente para registrar interacciones.",
        )


def guardar_eventos(usuario_id: UUID, eventos: list[EventoEntrada]) -> None:
    headers = _supabase_headers(service_role=True)
    headers["Prefer"] = "return=minimal"
    ahora = datetime.now(UTC)
    filas = []
    for evento in eventos:
        fila = evento.model_dump(mode="json")
        fila["usuario_id"] = str(usuario_id)
        fecha = evento.creado_en or ahora
        if fecha.tzinfo is None:
            fecha = fecha.replace(tzinfo=UTC)
        fila["creado_en"] = fecha.astimezone(UTC).isoformat()
        filas.append(fila)

    try:
        response = httpx.post(
            f"{settings.supabase_url.rstrip('/')}/rest/v1/eventos",
            headers=headers,
            json=filas,
            timeout=8.0,
        )
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="No fue posible registrar los eventos.",
        ) from exc

    if response.status_code not in {200, 201, 204}:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="No fue posible registrar los eventos.",
        )


@router.post("")
def registrar_eventos(
    lote: LoteEventos,
    authorization: str | None = Header(default=None),
) -> dict[str, int]:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Autenticación requerida.",
        )

    token = authorization[7:].strip()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Autenticación requerida.",
        )

    usuario_id = autenticar_usuario(token)
    verificar_consentimiento(usuario_id)
    guardar_eventos(usuario_id, lote.eventos)
    return {"registrados": len(lote.eventos)}
