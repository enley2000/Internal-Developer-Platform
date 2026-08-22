# AI Operations Agent

_To be filled in during Phase 7._

Design principles:
- The agent investigates using tools (Kubernetes API, Prometheus, GitHub API,
  CI/CD status) rather than answering from general knowledge.
- The agent can propose a remediation but never applies it automatically —
  a human approves destructive/state-changing actions.
- Every tool call is logged for audit purposes.

Planned tools:
- get_pod_status()
- get_pod_logs()
- get_prometheus_metrics()
- get_deployment_history()
- get_pipeline_status()
- get_recent_commits()
