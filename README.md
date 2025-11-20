# Backstage on AKS (buildable + dockerized)

This repository packages the official [Backstage demo](https://github.com/backstage/demo) into a container image and provides AKS-ready configuration for PostgreSQL, NGINX ingress, Helm, and Azure integrations.

## What you get
- **Dockerfile** that clones and builds the Backstage demo app and produces a non-root runtime image.
- **app-config.example.yaml** and **app-config.production.yaml** tuned for AKS (PostgreSQL, Azure DevOps, TechDocs, Kubernetes plugin).
- **Plugin-ready configs** for Azure DevOps (catalog + pipelines), Grafana dashboard links, Git repos (GitHub and Azure DevOps), Kubernetes AKS status, and TechDocs.
- **helm/values-backstage.yaml** to deploy via the Backstage Helm chart with NGINX ingress and external PostgreSQL secrets.
- **catalog-info.plugins.yaml** and **docs/** showing a complete entity annotated for Azure DevOps pipelines, Grafana dashboards, Kubernetes, Git source, and TechDocs.

## Prerequisites
- Azure CLI authenticated and authorized for AKS, ACR, and PostgreSQL.
- Docker / BuildKit, kubectl, and Helm.
- Optional: [Azure Workload Identity](https://azure.github.io/azure-workload-identity/docs/introduction.html) for the Kubernetes plugin.

## 1) Build the Backstage container
The Dockerfile pulls the Backstage demo repo, overlays the plugin-friendly configs/docs from this repo, and builds the backend bundle. Customize `DEMO_REF` to pin a tag.

```bash
# Build
docker build -t <acr-name>.azurecr.io/backstage-demo:v1 \
  --build-arg DEMO_REF=v1.30.0 \
  .

# Push to ACR
az acr login --name <acr-name>
docker push <acr-name>.azurecr.io/backstage-demo:v1
```

## 2) Prepare AKS and database
```bash
RESOURCE_GROUP=rg-backstage
AKS_NAME=aks-backstage
ACR_NAME=<acr-name>

# Create cluster and attach ACR
az aks create --resource-group $RESOURCE_GROUP --name $AKS_NAME --attach-acr $ACR_NAME --node-count 3 --enable-managed-identity
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME

# Create PostgreSQL Flexible Server (example) and capture credentials
PG_HOST=<postgres-host>
PG_DB=backstage
PG_USER=backstage
PG_PASSWORD=<password>
```

Create the secret AKS will mount into the Backstage pods:
```bash
kubectl create secret generic backstage-db -n portal \
  --from-literal=host=$PG_HOST \
  --from-literal=database=$PG_DB \
  --from-literal=user=$PG_USER \
  --from-literal=password=$PG_PASSWORD

# Optional secret with plugin tokens/keys
kubectl create secret generic backstage-secrets -n portal \
  --from-literal=azureDevOpsToken=<PAT> \
  --from-literal=azureSubscriptionId=<subscription-id> \
  --from-literal=azureTenantId=<tenant-id> \
  --from-literal=githubToken=<gh-token> \
  --from-literal=githubClientId=<oauth-client-id> \
  --from-literal=githubClientSecret=<oauth-client-secret> \
  --from-literal=microsoftClientId=<aad-client-id> \
  --from-literal=microsoftClientSecret=<aad-client-secret> \
  --from-literal=grafanaApiKey=<grafana-api-key> \
  --from-literal=techdocsAccount=<storage-account> \
  --from-literal=techdocsAccountKey=<storage-key>
```

## 3) Deploy NGINX ingress and Backstage via Helm
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add backstage https://backstage.github.io/charts
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

helm upgrade --install portal backstage/backstage \
  --namespace portal --create-namespace \
  -f helm/values-backstage.yaml \
  --set image.repository=<acr-name>.azurecr.io/backstage-demo \
  --set image.tag=v1
```

After deployment, verify:
```bash
kubectl get pods -n portal
kubectl get ingress -n portal
```

## 4) Configure the Backstage app
- Copy `app-config.example.yaml` to `app-config.yaml` for local testing (`yarn dev`) or override values in `app-config.production.yaml` through environment variables when running in AKS.
- Set `AZURE_DEVOPS_TOKEN` if you want Azure DevOps catalog and pipeline integration.
- Configure TechDocs Azure Blob Storage credentials via `TECHDOCS_AZURE_ACCOUNT`, `TECHDOCS_AZURE_KEY`, and optional `TECHDOCS_AZURE_CONTAINER`.
- Provide `GITHUB_TOKEN` when importing GitHub repositories into the catalog.
- Provide `GRAFANA_URL` and `GRAFANA_API_KEY` so catalog entities annotated with Grafana dashboards can render links.
- For the Kubernetes plugin on AKS, prefer Azure Workload Identity and set `AZURE_SUBSCRIPTION_ID` and `AZURE_TENANT_ID`.
- Configure optional OAuth clients for sign-in (`GITHUB_OAUTH_CLIENT_ID/SECRET`, `MICROSOFT_CLIENT_ID/SECRET`, `AZURE_TENANT_ID`).

## 5) Plugin configuration
- **Azure DevOps pipelines & repos**: set `AZURE_DEVOPS_TOKEN`, `AZURE_DEVOPS_ORG`, and `AZURE_DEVOPS_PROJECT`. The catalog provider will ingest services from the project repos, and the proxy at `/azure-devops-api` lets the Azure DevOps plugin fetch pipeline status.
- **Grafana dashboards**: set `GRAFANA_URL` and `GRAFANA_API_KEY`. Add `grafana/dashboardUrls` annotations to catalog entities so Backstage links dashboards per service. A proxy at `/grafana-api` is available for plugins that need API access.
- **Git repos (GitHub + Azure DevOps)**: supply `GITHUB_TOKEN` for GitHub entities, and Backstage will use the same Azure DevOps token above for DevOps repos. Add your repos to `catalog.locations` or rely on the Azure DevOps provider.
- **Kubernetes (AKS status)**: configure `AZURE_SUBSCRIPTION_ID` and `AZURE_TENANT_ID`; use Azure Workload Identity for the pod service account to enable read-only cluster visibility via the Kubernetes plugin.
- **TechDocs**: set Azure Blob Storage variables and annotate catalog entities with `backstage.io/techdocs-ref` to host docs via TechDocs.

## 6) Plugin sample content
- `catalog-info.plugins.yaml` defines a service with Azure DevOps pipeline annotations, a Grafana dashboard UID, AKS label selector, Git source reference, and TechDocs link so you can import it immediately.
- `docs/` contains a TechDocs-ready MkDocs site for the same sample service. The Dockerfile copies these files into the image so you can `register` the entity and `techdocs-cli generate` without extra setup.

## Notes
- The container runs as non-root UID `10001` and listens on port `7007`.
- The Docker build uses the Backstage demo repo directly to keep this repository small; fork the demo if you need custom features.
