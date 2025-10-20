from fastapi.testclient import TestClient
from app.main import app
from datetime import datetime

client = TestClient(app)

def test_ping_ok():
    r = client.get("/ping")
    assert r.status_code == 200
    body = r.json()
    assert body == {"status": "ok"}
    assert r.headers["content-type"].startswith("application/json")

def test_root_ok_and_datetime_iso():
    r = client.get("/")
    assert r.status_code == 200
    body = r.json()
    assert "message" in body and body["message"]
    assert "fecha_hora" in body and isinstance(body["fecha_hora"], str)

    # Debe ser ISO 8601 parseable (FastAPI serializa datetime automáticamente)
    datetime.fromisoformat(body["fecha_hora"])
