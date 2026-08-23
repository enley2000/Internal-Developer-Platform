# Terraform â€” Azure Infrastructure

Provisions everything under the "Infrastructure" layer of the architecture:
Resource Group, VNet with public/private subnets, AKS, Container Registry,
Key Vault, Log Analytics, and Storage.

## Files

| File | What it creates |
|---|---|
| `providers.tf` | Which provider (Azure) and version, plus how/where state is stored |
| `variables.tf` | Every configurable input, with defaults and validation |
| `main.tf` | Resource Group â€” the container everything else lives in |
| `network.tf` | VNet, public/private subnets, NSGs â€” the design from `docs/architecture.md` |
| `acr.tf` | Container Registry + least-privilege role assignment for AKS to pull from it |
| `keyvault.tf` | Key Vault + role assignment for AKS to read secrets from it |
| `aks.tf` | The Kubernetes cluster itself |
| `monitoring.tf` | Log Analytics workspace (cluster-level monitoring) + Storage account |
| `outputs.tf` | Values printed after `apply` â€” cluster name, ACR hostname, etc. |

## Without an Azure subscription (where things stand right now)

You don't need Azure credentials to check that this code is well-formed.
From inside `terraform/`:

```bash
terraform init      # downloads the azurerm provider plugin â€” no login needed
terraform fmt -check  # checks formatting is consistent
terraform validate  # checks the code is syntactically correct and internally consistent
```

`terraform plan` and `terraform apply` are the ones that need real Azure
credentials (`az login`), because they actually talk to Azure to work out
what would change / to create resources. Hold off on those until you're
ready to pay for a running AKS cluster â€” it bills by the hour regardless
of traffic.

## When you do get an Azure account

1. `az login`
2. `cp terraform.tfvars.example terraform.tfvars` and adjust if needed
3. `terraform init`
4. `terraform plan` â€” review exactly what it intends to create before touching anything real
5. `terraform apply`
6. Run the `get_aks_credentials_command` from the outputs to point `kubectl` at your new cluster

## Cost-consciousness built into the defaults

- `aks_node_count = 1` and a small VM size â€” enough to demonstrate the
  design, not production capacity
- `enable_azure_firewall = false` â€” Azure Firewall has a large fixed
  hourly cost; the subnet for it is still reserved in `network.tf` so the
  design is complete even though it's switched off
- ACR SKU is `Basic`, Storage replication is `LRS` (cheapest tier)

Being able to explain *why* these are scaled down â€” not just that they
are â€” is worth more in an interview than a maxed-out config you can't
actually afford to run.
