# Backstage on AKS

This repo documents how to build a Backstage application, containerize it, and deploy it to Azure Kubernetes Service (AKS) with a production-ready configuration that includes NGINX Ingress, Azure Container Registry (ACR), PostgreSQL, Helm-based releases, and common value-adding plugins.

## Prerequisites
- Azure CLI logged in with permissions to create ACR, AKS, and Azure Database for PostgreSQL Flexible Server.
- kubectl and Helm configured locally.
- Node.js 18+ and Yarn for local Backstage builds.
- Docker or BuildKit-enabled tooling.

## 1) Create and build the Backstage app
```bash
# Create the portal
npx @backstage/create-app@latest --path my-portal
cd my-portal

# Install dependencies and verify
yarn install
yarn test

# Build the production bundle
yarn build
```

## 2) Build and push the container image to ACR
```bash
# Variables
ACR_NAME=myacr123
IMAGE=backstage-app
TAG=v1

# Create ACR and log in
az acr create --name $ACR_NAME --resource-group rg-portal --sku Standard
az acr login --name $ACR_NAME

# Build and push
az acr build --registry $ACR_NAME --image $IMAGE:$TAG .
# or locally
# docker build -t $ACR_NAME.azurecr.io/$IMAGE:$TAG .
# docker push $ACR_NAME.azurecr.io/$IMAGE:$TAG
```

## 3) Provision AKS and connect it to ACR
```bash
AKS_NAME=aks-portal
az aks create --name $AKS_NAME --resource-group rg-portal --attach-acr $ACR_NAME --node-count 3 --enable-managed-identity
az aks get-credentials --name $AKS_NAME --resource-group rg-portal
```

## 4) Deploy PostgreSQL
Use Azure Database for PostgreSQL Flexible Server or a managed Postgres helm chart. Capture the connection string for Backstage.
```bash
PG_HOST=<postgres-hostname>
PG_USER=<user>
PG_PASSWORD=<password>
PG_DB=backstage
```

## 5) Configure Backstage for AKS
Update `app-config.yaml`:
```yaml
backend:
  baseUrl: https://portal.example.com
  database:
    client: pg
    connection:
      host: ${PG_HOST}
      port: 5432
      user: ${PG_USER}
      password: ${PG_PASSWORD}
      database: ${PG_DB}
  kubernetes:
    serviceLocatorMethod: multiTenant
    clusterLocatorMethods:
      - type: azure
        authProvider: azureWorkloadIdentity
        subscriptionId: <subscription-id>
        tenantId: <tenant-id>
```

### Plugins to enable
- **Software Catalog**: add `catalog-info.yaml` entries for AKS services and Git repos; set `integrations.azure.devOps` for repo discovery.
- **Kubernetes plugin**: configure the `kubernetes` section above and add RBAC for read-only service accounts.
- **Azure DevOps pipelines**: configure `integrations.azure.devOps` and `proxy` rules to the ADO API.
- **TechDocs**: enable `techdocs.builder: 'local'` and store docs in the catalog repos; point `techdocs.publisher.type` to Azure Blob storage if desired.
- **Golden templates**: add `templates/` that create AKS services with repo, Dockerfile, Helm chart, ADO pipeline YAML, and `catalog-info.yaml`.
- **Grafana links**: use `app-config.yaml` `monitoring.grafana` links in the catalog entity metadata.

## 6) Deploy with Helm
Create a values file `values-backstage.yaml` that references your ACR image and secrets:
```yaml
image:
  repository: <acr-name>.azurecr.io/backstage-app
  tag: v1
  pullSecrets:
    - name: acr-pull

service:
  type: ClusterIP
  port: 7000

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: portal.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - hosts:
        - portal.example.com
      secretName: portal-tls

postgresql:
  enabled: false # using external Azure DB
```

Deploy NGINX Ingress and Backstage:
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace

helm repo add backstage https://backstage.github.io/charts
helm repo update
helm install portal backstage/backstage -f values-backstage.yaml -n portal --create-namespace
```

## 7) Validate and operate
```bash
kubectl get pods -n portal
kubectl get ingress -n portal
# Browse https://portal.example.com once DNS points to the ingress IP
```

For detailed Backstage app setup guidance, see the official docs: https://backstage.io/docs/getting-started/
