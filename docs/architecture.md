# Architecture

## Goal

A developer wants to deploy `customer-api`. Instead of manually creating
infrastructure, they describe the app and the platform does the rest.

```yaml
application:
  name: customer-api
  language: python
  environment: dev
  replicas: 2
  database: postgres
```

## Flow

1. **Infrastructure (Terraform → Azure)**
   Resource Group, AKS, Container Registry, Key Vault, Storage, Monitoring —
   provisioned as code, not clicked together in the portal.

2. **Build (GitHub Actions)**
   `git push → tests → security scan → docker build → push image → deploy`

3. **Deploy (Kubernetes / Helm)**
   Namespace, Deployment, Service, Ingress, ConfigMap, Secrets — templated
   with Helm so the same chart works across dev/staging/prod.

4. **Observe (Prometheus + Grafana)**
   CPU, memory, request rate, latency, error rate, pod restarts, availability.
   SLO: 99.9% availability. SLI: successful HTTP requests / total requests.

5. **Operate (AI agent)**
   The AI agent has read-only tools — `get_pod_status`, `get_pod_logs`,
   `get_prometheus_metrics`, `get_deployment_history`, `get_pipeline_status`,
   `get_recent_commits` — so it can investigate ("why is customer-api
   unhealthy?") instead of just answering from a prompt. It can *propose* a
   remediation (e.g. rollback), but a human approves it — see
   [ai-agent.md](ai-agent.md) for why that boundary matters.

## Network design (Azure)

```
VNet
 |-- Public subnet     (ingress only)
 |-- Private subnet    (AKS nodes — not exposed to the internet)
 |-- AKS
 |-- Private Endpoint  (Key Vault, ACR access stays off the public internet)
 |-- Azure Firewall
```

Application workloads sit in private subnets. Traffic enters only through
the ingress layer; access to platform services (Key Vault, ACR) goes over
private connectivity rather than public endpoints.

## CI/CD pipeline stages

```
git push → lint → unit tests → SAST → dependency scan → docker build →
container scan → push image → deploy staging → integration tests →
approval → production
```

Each stage exists to catch a specific class of problem before it reaches
production — see [security.md](security.md) for the reasoning per stage.

## Why AKS instead of a single VM / raw Docker

Multiple replicas, rolling deploys without downtime, self-healing
(CrashLoopBackOff → restart), declarative config (what "correct" looks like
is in Git, not in someone's head), and it's what a real client environment
at this scale would actually run.
