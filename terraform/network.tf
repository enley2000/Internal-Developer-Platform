# network.tf
#
# WHAT THIS IMPLEMENTS
# ---------------------
# The network design described in docs/architecture.md:
#
#   VNet
#    |-- Public subnet    (ingress only)
#    |-- Private subnet   (AKS nodes â€” not exposed to the internet)
#    |-- AKS
#    |-- Private Endpoint (Key Vault, ACR access stays off the public internet)
#    |-- Azure Firewall   (optional, see enable_azure_firewall)
#
# WHY SPLIT INTO PUBLIC/PRIVATE SUBNETS AT ALL
# -----------------------------------------------
# This is the answer to "why?" that docs/architecture.md talks about
# being able to give in the interview:
#
#   AKS nodes go in the private subnet because there's no reason for the
#   VMs running your pods to have a direct path to the public internet.
#   The only thing that should be internet-facing is the ingress
#   controller/load balancer, which lives at the edge of the public
#   subnet. Everything else â€” database access, Key Vault, ACR pulls â€”
#   happens over private connectivity inside the VNet.
#
# This is a genuinely common real-world pattern, not something invented
# for the demo â€” it's what "workloads in private subnets" means in
# almost every Azure/AWS landing zone design.

resource "azurerm_virtual_network" "main" {
  name                = "${local.name_prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Public subnet â€” only the ingress/load balancer lives here.
resource "azurerm_subnet" "public" {
  name                 = "${local.name_prefix}-public-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Private subnet â€” AKS nodes live here. No public IPs, no direct inbound
# internet access. Delegated so AKS can manage it.
resource "azurerm_subnet" "private" {
  name                 = "${local.name_prefix}-private-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Reserved for Private Endpoints (Key Vault, ACR) â€” keeps traffic to
# those services inside the VNet instead of over the public Azure backbone.
resource "azurerm_subnet" "private_endpoints" {
  name                 = "${local.name_prefix}-pe-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]

  private_endpoint_network_policies_enabled = true
}

# Azure Firewall needs its own subnet with this exact name â€” Azure
# requires it to be called "AzureFirewallSubnet". Only created if the
# firewall itself is enabled (see variables.tf for why it's off by default).
resource "azurerm_subnet" "firewall" {
  count                = var.enable_azure_firewall ? 1 : 0
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.4.0/26"]
}

# Network Security Group for the private subnet â€” this is what actually
# enforces "no direct inbound internet access" at the network level,
# not just by convention.
resource "azurerm_network_security_group" "private" {
  name                = "${local.name_prefix}-private-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}
