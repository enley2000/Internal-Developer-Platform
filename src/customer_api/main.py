"""
customer-api
------------
A small FastAPI service that stands in for "the developer's application"
in the Internal Developer Platform demo.

It's intentionally simple (CRUD over customers) but wired up the way a
real service would be:
  - structured health/readiness endpoints (K8s probes use these)
  - Prometheus metrics endpoint
  - a /simulate-failure endpoint used later to trigger the AI incident demo
  - config via environment variables (12-factor style)
"""

import os
import random
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Response
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from pydantic import BaseModel

from .database import Base, engine, get_session
from .models import Customer

# ---------------------------------------------------------------------------
# Metrics (scraped by Prometheus later in Phase 5)
# ---------------------------------------------------------------------------
REQUEST_COUNT = Counter(
    "customer_api_requests_total", "Total requests", ["method", "endpoint", "status"]
)
REQUEST_LATENCY = Histogram(
    "customer_api_request_latency_seconds", "Request latency", ["endpoint"]
)

# Feature flag used to demo a broken deployment (Phase 8: simulated incident)
FAIL_MODE = os.getenv("SIMULATE_DB_FAILURE", "false").lower() == "true"


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create tables on startup. In a real system this would be a migration
    # (alembic) run as a separate CI/CD step, not on app boot.
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(title="customer-api", version="0.1.0", lifespan=lifespan)


class CustomerIn(BaseModel):
    name: str
    email: str


class CustomerOut(CustomerIn):
    id: int


# ---------------------------------------------------------------------------
# Health / readiness — these are what Kubernetes liveness/readiness probes
# and the AI agent's get_pod_status()/get_pod_logs() tooling hook into.
# ---------------------------------------------------------------------------
@app.get("/health/live")
def liveness():
    return {"status": "ok"}


@app.get("/health/ready")
def readiness():
    if FAIL_MODE:
        # Simulates the "database connection broken" incident from the plan
        raise HTTPException(status_code=500, detail="database connection failed")
    return {"status": "ready"}


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


# ---------------------------------------------------------------------------
# Business endpoints
# ---------------------------------------------------------------------------
@app.post("/customers", response_model=CustomerOut, status_code=201)
def create_customer(payload: CustomerIn):
    start = time.time()
    if FAIL_MODE:
        REQUEST_COUNT.labels("POST", "/customers", "500").inc()
        raise HTTPException(status_code=500, detail="database connection failed")

    with get_session() as session:
        customer = Customer(name=payload.name, email=payload.email)
        session.add(customer)
        session.commit()
        session.refresh(customer)

    REQUEST_COUNT.labels("POST", "/customers", "201").inc()
    REQUEST_LATENCY.labels("/customers").observe(time.time() - start)
    return customer


@app.get("/customers/{customer_id}", response_model=CustomerOut)
def get_customer(customer_id: int):
    start = time.time()
    if FAIL_MODE:
        REQUEST_COUNT.labels("GET", "/customers/{id}", "500").inc()
        raise HTTPException(status_code=500, detail="database connection failed")

    with get_session() as session:
        customer = session.get(Customer, customer_id)
        if not customer:
            REQUEST_COUNT.labels("GET", "/customers/{id}", "404").inc()
            raise HTTPException(status_code=404, detail="customer not found")

    REQUEST_COUNT.labels("GET", "/customers/{id}", "200").inc()
    REQUEST_LATENCY.labels("/customers/{id}").observe(time.time() - start)
    return customer


@app.get("/customers", response_model=list[CustomerOut])
def list_customers():
    with get_session() as session:
        return session.query(Customer).all()


# ---------------------------------------------------------------------------
# Used in Phase 8 to deliberately break the service for the incident demo.
# A real platform wouldn't ship this — it's here purely so you can flip an
# env var / ConfigMap value and watch Grafana + the AI agent react.
# ---------------------------------------------------------------------------
@app.get("/_debug/random-latency")
def random_latency():
    time.sleep(random.uniform(0, 1.5))
    return {"status": "ok"}
