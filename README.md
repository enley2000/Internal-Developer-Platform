# AI-Powered Internal Developer Platform

A miniature Internal Developer Platform: a developer describes an application,
the platform provisions the cloud infrastructure, builds and deploys it,
monitors it, and gives an AI agent tools to investigate and explain incidents.

Built as a portfolio project to demonstrate practical Platform/DevOps
engineering â€” cloud infrastructure, IaC, containers, CI/CD, observability,
security, and AI-assisted operations working together end to end, rather
than as five separate tutorial projects.

## Status

This repo is being built in phases. Current status:

| Phase | Scope | Status |
|---|---|---|
| 1 | Python service (`customer-api`) + Docker | âœ… done |
| 2 | Terraform â†’ Azure (AKS, ACR, Key Vault, networking) | âœ… written, not yet applied (no Azure subscription yet) |
| 3 | Kubernetes manifests / Helm chart | â¬œ next |
| 4 | GitHub Actions CI/CD (build â†’ scan â†’ push â†’ deploy) | â¬œ |
| 5 | Prometheus + Grafana observability | â¬œ |
| 6 | DevSecOps (Trivy, secret scanning, RBAC, Key Vault) | â¬œ |
| 7 | AI operations agent (tools over K8s/Prometheus/GitHub) | â¬œ |
| 8 | Simulated production incident demo | â¬œ |
| 9 | Architecture diagrams + docs | â¬œ |
| 10 | Interview prep notes | â¬œ |

## Architecture

See [docs/architecture.md](docs/architecture.md) for the full design. Short
version:

```
Developer
   |
   v
Developer Portal / API
   |
   v
AI Platform Assistant
   |
   +---------+-----------+
   v         v           v
Terraform  GitHub      Kubernetes
   |       Actions        |
   v         |            v
 Azure      CI/CD        AKS
   |__________|____________|
              |
              v
      Monitoring Layer
      Prometheus + Grafana
              |
              v
      AI Operations / AIOps
```

## `customer-api`

The sample application the platform deploys. A small FastAPI service with:

- `GET /health/live`, `GET /health/ready` â€” Kubernetes probe targets
- `GET /metrics` â€” Prometheus scrape target
- `POST /customers`, `GET /customers`, `GET /customers/{id}` â€” the actual app
- `SIMULATE_DB_FAILURE=true` env var â€” flips the service into a broken state
  on purpose, used for the Phase 8 incident demo

### Run locally

```bash
pip install -r requirements.txt
uvicorn src.customer_api.main:app --reload
```

### Run with Docker Compose (app + Postgres)

```bash
docker compose up --build
```

### Run tests

```bash
pytest tests/ -v
```

## Repo layout

```
src/customer_api/   the application
tests/               pytest suite
terraform/           Azure infrastructure (Phase 2)
kubernetes/helm/     Helm chart for AKS deployment (Phase 3)
.github/workflows/   CI/CD pipeline (Phase 4)
docs/                architecture, security, deployment, incident-response, ai-agent
```