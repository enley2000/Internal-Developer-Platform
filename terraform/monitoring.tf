# monitoring.tf
#
# Log Analytics Workspace â€” the destination AKS's oms_agent (aks.tf)
# ships container logs and cluster-level metrics to. This is separate
# from the Prometheus/Grafana stack coming in Phase 5: think of this one
# as Azure's own view of "is the cluster healthy" (node health, control
# plane, container logs), while Prometheus/Grafana in Phase 5 will be
# the application-level view (request latency, error rate, pod restarts)
# that the AI agent queries in Phase 7.

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.name_prefix}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days    = 30
  tags                = var.tags
}

# storage.tf equivalent â€” kept here since it's small. Used for anything
# the platform needs to persist outside the cluster (e.g. Terraform
# state, if you switch on the remote backend in providers.tf; or app
# file storage later).
resource "azurerm_storage_account" "main" {
  name                     = "${var.project_name}${var.environment}sa" # storage account names: lowercase, no hyphens, globally unique
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # cheapest replication tier â€” fine for a demo, prod would likely use GRS
  tags                     = var.tags
}
