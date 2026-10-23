from uuid import UUID

from fastapi.testclient import TestClient

from app.api.v1 import events
from app.main import app

client = TestClient(app)
USER_ID = UUID("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
SESSION_ID = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"


def test_events_requires_authentication() -> None:
    response = client.post(
        "/v1/eventos",
        json={
            "eventos": [
                {
                    "tipo": "busqueda",
                    "entidad_tipo": "consulta",
                    "sesion_id": SESSION_ID,
                }
            ]
        },
    )
    assert response.status_code == 401


def test_events_rejects_mismatched_entity_type() -> None:
    response = client.post(
        "/v1/eventos",
        headers={"Authorization": "Bearer token"},
        json={
            "eventos": [
                {
                    "tipo": "ver_restaurante",
                    "entidad_tipo": "plato",
                    "entidad_id": "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
                    "sesion_id": SESSION_ID,
                }
            ]
        },
    )
    assert response.status_code == 422


def test_events_registers_authenticated_user_and_checks_consent(monkeypatch) -> None:
    monkeypatch.setattr(events, "autenticar_usuario", lambda token: USER_ID)
    consentimientos_verificados: list[UUID] = []
    eventos_guardados: list[tuple[UUID, list[events.EventoEntrada]]] = []

    monkeypatch.setattr(
        events,
        "verificar_consentimiento",
        lambda user_id: consentimientos_verificados.append(user_id),
    )
    monkeypatch.setattr(
        events,
        "guardar_eventos",
        lambda user_id, event_list: eventos_guardados.append((user_id, event_list)),
    )

    response = client.post(
        "/v1/eventos",
        headers={"Authorization": "Bearer valid-token"},
        json={
            "eventos": [
                {
                    "tipo": "busqueda",
                    "entidad_tipo": "consulta",
                    "origen": "busqueda",
                    "sesion_id": SESSION_ID,
                    "termino": "pizza",
                }
            ]
        },
    )

    assert response.status_code == 200
    assert response.json() == {"registrados": 1}
    assert consentimientos_verificados == [USER_ID]
    assert eventos_guardados[0][0] == USER_ID
    assert eventos_guardados[0][1][0].termino == "pizza"
