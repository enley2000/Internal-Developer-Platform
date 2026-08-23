# providers.tf
#
# WHAT THIS FILE DOES
# --------------------
# Tells Terraform two things:
#   1. Which "provider" plugin to use to talk to a cloud (here: azurerm,
#      HashiCorp's official Azure provider) and which version of it.
#   2. Where to store the "state file" â€” Terraform's record of what it
#      last created, so it knows what to change on the next apply.
#
# WHY PIN VERSIONS
# -----------------
# Without a version constraint, `terraform init` grabs the latest provider
# version every time â€” which can silently change behaviour between your
# laptop and CI, or between today and six months from now. Pinning to a
# range (~> 3.100) means "3.100.x is fine, but don't jump to 4.x without
# me deciding to".

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  # State is what makes Terraform different from just clicking around the
  # Azure portal: it's a JSON file that maps "this Terraform resource" to
  # "this actual Azure object ID". Storing it locally (the default) is
  # fine solo, but it means only your laptop knows what's deployed, and
  # it's easy to lose. The commented block below is the real answer:
  # store state in an Azure Storage blob so it survives, and so CI/CD can
  # run `terraform apply` without needing your local state file.
  #
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "idpplatformtfstate"
  #   container_name       = "tfstate"
  #   key                  = "idp-platform.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      # Without this, `terraform destroy` leaves deleted Key Vaults in a
      # "soft-deleted" state that blocks recreating a vault with the same
      # name for 90 days. Fine for prod, annoying for a portfolio project
      # you'll tear down and rebuild while iterating.
      purge_soft_delete_on_destroy = true
    }
  }
}
