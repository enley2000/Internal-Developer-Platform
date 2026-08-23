# acr.tf
#
# WHAT THIS IS
# ------------
# Azure Container Registry — where the Docker image built in
# .github/workflows/ci.yml gets pushed after a successful build, and
# where AKS pulls it from during deployment.
#
# WHY GRANT AKS ACCESS VIA A ROLE ASSIGNMENT INSTEAD OF A PASSWORD
# --------------------------------------------------------------------
# The "AcrPull" role assignment below is the least-privilege way to let
# AKS pull images: AKS's managed identity is granted exactly one
# permission (pull images) on exactly one resource (this registry) —
# nothing else. The alternative (admin_enabled = true, using a shared
# username/password) works but is a credential that has to be stored
# somewhere and rotated. This is the same "why" that comes up under
# DevSecOps in docs/security.md: prefer identity-based access over
# shared secrets wherever the platform supports it.

resource "azurerm_container_registry" "main" {
  name                = "${var.project_name}${var.environment}acr" # ACR names can't contain hyphens
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic" # Basic is enough for a portfolio project; Premium adds geo-replication/private endpoints
  admin_enabled       = false   # deliberately off — see comment above
  tags                = var.tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}
