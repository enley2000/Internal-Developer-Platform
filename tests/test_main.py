import os
import sys

#Force the test to use the local version of the app, not an installed version.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

os.environ["DATABASE_URL"] = "sqlite:///./test.db"

import pytest
from fastapi.testclient import TestClient

from src.customer_api.main import app


@pytest.fixture()
def client():
    # TestClient as a context manager triggers FastAPI's lifespan
    # (startup/shutdown) events, which is what creates the DB tables.
    with TestClient(app) as c:
        yield c


def test_liveness(client):
    resp = client.get("/health/live")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_readiness(client):
    resp = client.get("/health/ready")
    assert resp.status_code == 200


def test_create_and_get_customer(client):
    create_resp = client.post(
        "/customers", json={"name": "Ada Lovelace", "email": "ada@example.com"}
    )
    assert create_resp.status_code == 201
    customer_id = create_resp.json()["id"]

    get_resp = client.get(f"/customers/{customer_id}")
    assert get_resp.status_code == 200
    assert get_resp.json()["name"] == "Ada Lovelace"


def test_get_missing_customer_returns_404(client):
    resp = client.get("/customers/999999")
    assert resp.status_code == 404


def test_metrics_endpoint_exposes_prometheus_format(client):
    resp = client.get("/metrics")
    assert resp.status_code == 200
    assert b"customer_api_requests_total" in resp.content
