#!/usr/bin/env bash
set -euo pipefail

APP_DIR=${APP_DIR:-cnhi-backstage}
APP_NAME=${APP_NAME:-cnhi-backstage}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

if [ ! -d "$APP_DIR" ]; then
  echo "Creating Backstage app at $APP_DIR"
  npx @backstage/create-app@latest --name "$APP_NAME" --path "$APP_DIR" --skip-install || {
    echo "Failed to scaffold via create-app; ensure npm can reach registry." >&2
    exit 1
  }
fi

cd "$APP_DIR"

echo "Installing dependencies"
yarn install --frozen-lockfile

echo "Installing required plugins"
yarn add --cwd packages/app @backstage/plugin-azure-devops @backstage/plugin-grafana @backstage/plugin-kubernetes @backstage/plugin-techdocs

yarn add --cwd packages/backend @backstage/plugin-azure-devops-backend @backstage/plugin-kubernetes-backend @backstage/plugin-techdocs-backend


echo "Applying app and backend templates"
cp "$REPO_ROOT/templates/app/App.tsx" packages/app/src/App.tsx
cp "$REPO_ROOT/templates/app/components/Root/Root.tsx" packages/app/src/components/Root/Root.tsx

cp "$REPO_ROOT/templates/backend/Dockerfile" packages/backend/Dockerfile

if [ -f "$REPO_ROOT/app-config.example.yaml" ]; then
  cp "$REPO_ROOT/app-config.example.yaml" app-config.yaml
fi
if [ -f "$REPO_ROOT/app-config.production.yaml" ]; then
  cp "$REPO_ROOT/app-config.production.yaml" app-config.production.yaml
fi
if [ -f "$REPO_ROOT/catalog-info.plugins.yaml" ]; then
  cp "$REPO_ROOT/catalog-info.plugins.yaml" catalog-info.yaml
fi

mkdir -p kubernetes
cp "$REPO_ROOT/templates/kubernetes/deployment.yaml" kubernetes/deployment.yaml
cp "$REPO_ROOT/templates/kubernetes/ingress.yaml" kubernetes/ingress.yaml
cp "$REPO_ROOT/templates/kubernetes/service.yaml" kubernetes/service.yaml

if [ -d "$REPO_ROOT/docs" ]; then
  mkdir -p docs
  cp -r "$REPO_ROOT/docs"/* docs/
fi

echo "Ready. Run 'yarn dev' for local dev or 'yarn build:backend && yarn backstage-cli package start' for image builds."
