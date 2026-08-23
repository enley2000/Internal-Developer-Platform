# aks.tf
#
# WHAT THIS IS
# ------------
# The Kubernetes cluster itself â€” where kubernetes/helm/ (Phase 3) will
# actually deploy customer-api.
#
# KEY DECISIONS, AND WHY (the kind of thing worth saying out loud in
# the interview instead of just "I used AKS"):
#
#   - vnet_subnet_id = private subnet: nodes get no public IP, matching
#     the network design in docs/architecture.md.
#   - identity block (SystemAssigned): AKS gets its own managed identity
#     instead of a static service principal + secret. One less credential
#     to store or rotate.
#   - key_vault_secrets_provider: enables the AKS Secrets Store CSI
#     driver, so pods can mount Key Vault secrets as files/env vars
#     without the app ever handling a Key Vault credential itself.
#   - oms_agent (Log Analytics): wires the cluster into Azure Monitor
#     for container insights â€” this is Azure-native and separate from
#     Prometheus/Grafana (Phase 5), which we'll run ourselves inside the
#     cluster for the app-level metrics.
#   - node_count = 1 by default (variables.tf): a portfolio demo doesn't
#     need HA node pools; the point being demonstrated is the design,
#     not running production capacity.

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${local.name_prefix}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${local.name_prefix}-aks"
  tags                = var.tags

  default_node_pool {
    name           = "default"
    node_count     = var.aks_node_count
    vm_size        = var.aks_node_vm_size
    vnet_subnet_id = azurerm_subnet.private.id
  }

  # System-assigned managed identity â€” Azure creates and manages the
  # credential for us; it's never something we generate, store, or pass
  # around as a secret.
  identity {
    type = "SystemAssigned"
  }

  # Lets pods read secrets directly from Key Vault (see keyvault.tf).
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure" # enforces Kubernetes NetworkPolicy resources â€” namespace/pod-level traffic rules on top of the NSG's subnet-level rules
  }
}
