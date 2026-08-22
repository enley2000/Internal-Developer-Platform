# Incident Response

_To be filled in during Phase 8 (simulated incident demo)._

Will walk through the "database connection broken" demo end to end:
1. `SIMULATE_DB_FAILURE=true` is set, error rate/latency/pod restarts spike
2. Grafana alert fires
3. AI agent investigates (pods, logs, metrics, deployment history, recent commits)
4. AI agent produces an incident summary + recommended action
5. Human approves the rollback
6. Post-incident notes
