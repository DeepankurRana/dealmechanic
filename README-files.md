# DealMechanic Infrastructure as Code (IaC)

> **DevOps-ready README** for the DealMechanic Azure IaC repository. Copy this file as your root `README.md`.

---

## 📌 Overview
This repo provisions DealMechanic Azure resources using **Bicep** with optional CI/CD via **Azure DevOps Pipelines**. It includes structure, commands, and a pipeline template so teams can deploy consistently across environments.

![DealMechanic Topology](./DealMechanic-Solution-Diagrams-27082025.png)

**Audience**: Rackspace engineering & Ken (Mubadala Capital)

---

## 📁 Repository Structure
```
.
├─ bicep/
│  ├─ main.bicep                 # entry point
│  ├─ modules/                   # reusable modules
│  │  ├─ appservice/
│  │  ├─ acr/
│  │  ├─ keyvault/
│  │  ├─ sql/
│  │  ├─ redis/
│  │  ├─ networking/
│  │  └─ monitoring/
│  └─ env/                       # per-environment parameters
│     ├─ dev.parameters.json
│     ├─ test.parameters.json
│     └─ prod.parameters.json
├─ pipelines/
│  └─ azure-pipelines.yml        # Azure DevOps pipeline (CI/CD)
├─ .github/workflows/            # (optional) GitHub Actions equivalent
├─ tools/                        # scripts, linting, helpers
└─ README.md
```

> Tip: Keep modules small and composable. Favor private endpoints, managed identities, tagging, and policy-compliance.

---

## 🧱 Resource Inventory (Initial Components, Naming & SKUs)

### Summary Table
| Service | Resource Name | Private Endpoint | SKU / Tier |
|---|---|---|---|
| Container Apps | `caweb-use-mc-dm-dev-01` | `privateEndpoint-caweb-use-mc-dm-dev-01` | `P1v3` |
| App Service Plan | `asp-use-mc-dm-dev-01` | — | `P1v3` |
| Application Insights | `insights-use-mc-mc-dev-01` | — | — |
| Container Registry | `crusemcdmdev01` | `privateEndpoint-crusemcdmdev01` | `Premium` |
| Key Vault | `kv-use-mc-dm-dev-01` | `privateEndpoint-kv-use-mc-dm-dev-01` | `Standard` |
| Azure SQL Server | `sql-use-mc-dm-dev-01` | `privateEndpoint-sql-use-mc-dm-dev-01` | `Elastic Premium` |
| Azure SQL Database | `sql-use-mc-dm-dev-01-db-01` | — | `Elastic Premium` |
| Redis Cache | `redis-use-mc-dm-dev-01` | `privateEndpoint-redis-use-mc-dm-dev-01` | `C1 (Basic 1GB)` |
| Log Analytics Workspace | `law-use-mc-dm-dev-01` | — | — |
| Managed Identity | `mi-use-mc-dm-dev-01` | — | — |
| Virtual Network | `vnet-use-mc-dm-dev-01` | — | — |
| Subnet | `DealMechanicSubnet` | — | — |
| Subnet | `DealMechanicVNISubnet` | — | — |
| Network Security Group | `nsg--vnet-use-mc-dm-dev-01--RavenSubnet` | — | — |

> **Resource Group:** `DealMechanic_IaC`

---

## ✅ Prerequisites
- **Azure CLI** (2.53+): `az version`
- **Bicep CLI** (bundled with Azure CLI or standalone): `az bicep version`
- Access to the target **Azure subscription** and **Resource Group**
- (CI) Azure DevOps **Service Connection** to the subscription (contributor on RG or scoped RBAC)

Optional tooling:
- **PSRule for Azure** / **ARM-TTK** for additional linting
- **Pre-commit** for formatting/linting hooks

---

## ⚙️ Configuration
Create environment parameter files under `bicep/env/` (example `dev.parameters.json`):
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": { "value": "eastus" },
    "namePrefix": { "value": "use-mc-dm-dev-01" },
    "tags": { "value": { "env": "dev", "app": "dealmechanic", "owner": "mubadala" } },
    "skuAppServicePlan": { "value": "P1v3" },
    "skuAcr": { "value": "Premium" },
    "skuKeyVault": { "value": "Standard" },
    "skuSql": { "value": "ElasticPremium" },
    "skuRedis": { "value": "Basic_C1" }
  }
}
```
Adjust parameter names to match your `main.bicep` and module interfaces.

**Naming convention** (example):
```
<resource>-<region>-mc-dm-<env>-<nn>
# e.g., kv-use-mc-dm-dev-01
```

---

## 🚀 Deploy Locally (CLI)
1) **Login** and select subscription
```bash
az login
az account set --subscription <SUBSCRIPTION_ID>
```
2) **Create resource group** (if needed)
```bash
az group create -n DealMechanic_IaC -l eastus
```
3) **What-If** (preview changes)
```bash
az deployment group what-if   --resource-group DealMechanic_IaC   --template-file bicep/main.bicep   --parameters @bicep/env/dev.parameters.json
```
4) **Deploy**
```bash
az deployment group create   --resource-group DealMechanic_IaC   --template-file bicep/main.bicep   --parameters @bicep/env/dev.parameters.json
```

> For subscription-scope artifacts (e.g., policy/role), use `az deployment sub create` with a `targetScope = 'subscription'` Bicep.

---

## 🧪 Linting & Validation (optional)
```bash
# Validate & build
az bicep build --file bicep/main.bicep

# (If using PSRule for Azure)
pwsh -c "Install-Module PSRule.Rules.Azure -Scope CurrentUser -Force"
pwsh -c "Invoke-PSRule -InputPath bicep/"
```

---

## 🤖 Azure DevOps Pipeline
Create `pipelines/azure-pipelines.yml` and reference it from your ADO pipeline.

```yaml
trigger:
  branches:
    include: [ main ]
  paths:
    include:
      - bicep/**
      - pipelines/**

pr:
  branches:
    include: [ main, develop ]

variables:
  azureSubscription: 'svcconn-dealmechanic'   # Service Connection name
  resourceGroupName: 'DealMechanic_IaC'
  location: 'eastus'
  environment: 'dev'
  parametersFile: 'bicep/env/$(environment).parameters.json'

stages:
  - stage: Validate
    jobs:
      - job: WhatIf
        pool: { vmImage: 'ubuntu-latest' }
        steps:
          - checkout: self
          - task: AzureCLI@2
            displayName: Azure What-If
            inputs:
              azureSubscription: $(azureSubscription)
              scriptType: bash
              scriptLocation: inlineScript
              inlineScript: |
                az group create -n $(resourceGroupName) -l $(location)
                az deployment group what-if                   --resource-group $(resourceGroupName)                   --template-file bicep/main.bicep                   --parameters @$(parametersFile)

  - stage: Deploy
    dependsOn: Validate
    condition: and(succeeded(), eq(variables['Build.Reason'], 'Manual'))  # require manual run by default
    jobs:
      - deployment: DeployBicep
        environment: 'dealmechanic-$(environment)'
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self
                - task: AzureCLI@2
                  displayName: Deploy Bicep
                  inputs:
                    azureSubscription: $(azureSubscription)
                    scriptType: bash
                    scriptLocation: inlineScript
                    inlineScript: |
                      az group create -n $(resourceGroupName) -l $(location)
                      az deployment group create                         --resource-group $(resourceGroupName)                         --template-file bicep/main.bicep                         --parameters @$(parametersFile)
```

> To deploy automatically on merge, remove the `condition` gate, or add environment approvals.

---

## 🔐 Security & Governance Checklist
- Use **Managed Identity** for all workloads (avoid client secrets)
- Enable **Private Endpoints** (ACR, KV, SQL, Redis, App Service)
- Enforce **minimum TLS** and HTTPS-only
- Apply **tags** (env, owner, cost-center, data-classification)
- Set up **RBAC** with least privilege
- Configure **Log Analytics** and **Diagnostic settings** for all resources

---

## 🧭 Operations
- **Rollback**: Re-run deployment with previous parameter set or commit
- **Drift**: Use `what-if` regularly; consider nightly validation job
- **Cost**: Review SKUs; right-size non-prod (shut down schedules where possible)

---

## 📒 Appendix
- Environment shown: **dev**
- Region hint from naming: `use` → *US East*
- This README will evolve as the IaC matures.

---

## 🤝 Contributing
1. Create a feature branch
2. Add/modify modules & parameters
3. Run linting/what-if locally
4. Open a PR; ensure pipeline validation passes

## 📝 License
Internal use; add an explicit license if this repo will be shared externally.
