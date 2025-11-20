# AKS Sample Service

This TechDocs site demonstrates documentation hosting for Backstage on AKS.

## Pipelines
- Azure DevOps project: `${AZURE_DEVOPS_ORG:-example-org}` / `${AZURE_DEVOPS_PROJECT:-example-project}`
- Pipeline ID: `42`

## Operations
- Grafana dashboard UID: `lXFD823Vz`
- Kubernetes selector: `app=aks-sample-service`

## How to build locally
```bash
yarn install
yarn docs:generate
```
