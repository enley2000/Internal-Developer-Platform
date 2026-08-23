# keyvault.tf
#
# WHAT THIS IS
# ------------
# Where secrets live â€” database passwords, connection strings, API keys â€”
# instead of sitting in a Kubernetes ConfigMap or a GitHub Actions
# secret in plain text. AKS reads from here at runtime via a private
# connection (see the private endpoint reservation in network.tf).
#
# WHY A SEPARATE KEY VAULT AND NOT "JUST" KUBERNETES SECRETS
# ---------------------------------------------------------------
# Kubernetes Secrets are only base64-encoded, not encrypted, by default â€”
# anyone with read access to the cluster's etcd can decode them trivially.
# Key Vault gives you: actual encryption at rest, access via Azure AD
# identity (auditable â€” you can see exactly which identity read which
# secret and when), and secret rotation without redeploying pods.

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                       = "${var.project_name}-${var.environment}-kv"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # would be true in prod; false here so the vault can be cleanly destroyed while iterating
  tags                       = var.tags

  # Only Azure AD identities with an explicit role assignment can read
  # secrets â€” this is the modern replacement for Key Vault's older
  # "access policy" model, and it's what lets us reuse the same
  # least-privilege pattern as the ACR role assignment above.
  enable_rbac_authorization = true
}

resource "azurerm_role_assignment" "aks_keyvault_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id
}
