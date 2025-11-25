#!/usr/bin/env bash

set -e

echo "====================================================="
echo "      Backstage.io Full Installation Script"
echo "====================================================="

### 1. Update system packages
echo "[*] Updating system packages..."
if command -v apt >/dev/null 2>&1; then
  sudo apt update && sudo apt upgrade -y
else
  echo "[-] apt not found. This script is optimized for Debian/Ubuntu/WSL."
  echo "    Exiting."
  exit 1
fi

### 2. Install build tools + curl + wget + git
echo "[*] Installing build tools and basic utilities..."
sudo apt install -y build-essential make curl wget git

### 3. Install nvm (Node Version Manager)
echo "[*] Installing NVM (Node Version Manager)..."
if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1090
source "$NVM_DIR/nvm.sh"

### 4. Install Node.js (LTS Iron - Node 20)
echo "[*] Installing Node.js LTS (Node 20)..."
nvm install lts/iron
nvm use lts/iron

### 5. Enable Corepack + Yarn 4.4.1
echo "[*] Enabling corepack & setting Yarn 4.4.1..."
corepack enable
yarn set version 4.4.1

### 6. Install Docker (optional but recommended)
if ! command -v docker >/dev/null 2>&1; then
  echo "[*] Installing Docker..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER" || true
else
  echo "[*] Docker already installed."
fi

### 7. Ensure Git is installed
if ! command -v git >/dev/null 2>&1; then
  echo "[*] Installing Git..."
  sudo apt install -y git
fi

### 8. Create a Backstage App
echo
echo "====================================================="
echo " Backstage app creation wizard will start now!"
echo "====================================================="
echo

read -rp "Enter your Backstage app name (example: portal): " APP_NAME

npx @backstage/create-app@latest "$APP_NAME"

### 9. Final Instructions
echo
echo "====================================================="
echo "        Backstage Installation Completed!"
echo "====================================================="
echo "Your app is created in: $APP_NAME/"
echo
echo "To run Backstage:"
echo "-----------------------------------------------------"
echo "cd \"$APP_NAME\""
echo "yarn dev"
echo "-----------------------------------------------------"
echo
echo "Open your browser at: http://localhost:3000"
echo
echo "If Docker was just installed, logout/login (or reboot) so Docker group applies."
echo "====================================================="
