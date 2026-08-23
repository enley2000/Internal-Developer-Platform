# outputs.tf
#
# WHAT THIS IS
# ------------
# Values Terraform prints after `apply` (or that other tools/scripts can
# read via `terraform output`). Useful for two things:
#   1. So you don't have to go digging in the Azure portal for names/IDs
#      you need for the next step (e.g. `az aks get-credentials`).
#   2. Phase 4's CI/CD pipeline will read acr_login_server to know where
#      to push the Docker image, and aks_cluster_name to know which
#      cluster to deploy to.

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "acr_login_server" {
  value       = azurerm_container_registry.main.login_server
  description = "Registry hostname CI/CD pushes images to, e.g. idpplatformdevacr.azurecr.io"
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "get_aks_credentials_command" {
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
  description = "Run this after apply to configure kubectl against the new cluster."
}
