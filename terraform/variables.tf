# variables.tf
#
# WHAT THIS FILE DOES
# --------------------
# Declares every input the rest of the Terraform code needs, with a
# description, a type, and (where sensible) a default. Nothing here
# creates any Azure resource by itself â€” it's just the "settings panel".
#
# WHY NOT HARDCODE VALUES IN main.tf INSTEAD
# --------------------------------------------
# Two reasons this matters in an interview context:
#   1. Same code, different environments. Set var.environment = "staging"
#      instead of "dev" and (combined with naming below) you get a
#      parallel, isolated set of resources without copy-pasting files.
#   2. It's the difference between "I hardcoded a working demo" and
#      "I designed this to be reusable" â€” which is exactly the gap the
#      ChatGPT plan flagged between learning tools and demonstrating
#      engineering judgement.

variable "project_name" {
  description = "Short name used as a prefix for all resource names."
  type        = string
  default     = "idpplatform"
}

variable "environment" {
  description = "Deployment environment: dev, staging, or prod. Affects resource sizing and naming."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region to deploy into."
  type        = string
  default     = "westeurope"
}

variable "aks_node_count" {
  description = "Number of nodes in the default AKS node pool."
  type        = number
  default     = 1 # kept at 1 deliberately â€” this is a portfolio project, not production capacity
}

variable "aks_node_vm_size" {
  description = "VM size for AKS nodes. Standard_B2s is one of the cheapest options suitable for AKS, good for a demo cluster."
  type        = string
  default     = "Standard_B2s"
}

variable "enable_azure_firewall" {
  description = <<-EOT
    Whether to deploy Azure Firewall in front of the VNet.
    Defaults to false: Azure Firewall has a significant fixed hourly cost
    regardless of traffic, which doesn't make sense to run continuously
    for a portfolio project. The architecture (network.tf) still reserves
    the subnet for it, so it can be switched on with one variable change
    to demonstrate the full design if needed.
  EOT
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags applied to every resource, for cost tracking and ownership."
  type        = map(string)
  default = {
    project = "idp-platform"
    managed_by = "terraform"
  }
}
