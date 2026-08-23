# main.tf
#
# The Resource Group is Azure's top-level container â€” every resource
# below (network, AKS, ACR, Key Vault, monitoring) lives inside it.
# Deleting this one resource cleanly tears down everything else, which
# is exactly what you want for a project you're going to spin up and
# down repeatedly while iterating (unlike prod, where you'd never want
# a single delete to nuke everything).
#
# NAMING
# ------
# Using a locals block to build names consistently (e.g. "idpplatform-dev")
# instead of typing the same string in every file. If you rename the
# project later, you change it in one place.

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = var.tags
}
