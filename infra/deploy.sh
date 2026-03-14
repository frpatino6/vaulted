#!/bin/bash
set -e

# Vaulted — deploy script for GCP e2-micro
# Usage: ./infra/deploy.sh

VM_IP="34.57.81.166"
VM_USER="${VM_USER:-fernando}"
REPO_DIR="/home/$VM_USER/vaulted"

echo "==> Deploying Vaulted API to $VM_IP"

# 1. Push latest code to VM
echo "==> Syncing code..."
rsync -az --exclude='.git' --exclude='node_modules' --exclude='apps/mobile' \
  ./ "$VM_USER@$VM_IP:$REPO_DIR/"

# 2. Run docker compose on VM
echo "==> Building and restarting API..."
ssh "$VM_USER@$VM_IP" bash << 'REMOTE'
  set -e
  cd ~/vaulted

  # Copy prod env if not exists
  if [ ! -f .env.prod ]; then
    echo "ERROR: .env.prod not found on VM. Create it from .env.prod.example first."
    exit 1
  fi

  docker compose -f docker-compose.prod.yml down
  docker compose -f docker-compose.prod.yml build --no-cache
  docker compose -f docker-compose.prod.yml up -d

  echo "==> Waiting for health check..."
  sleep 10
  docker compose -f docker-compose.prod.yml ps
  curl -sf http://localhost:3000/health && echo "==> API is UP" || echo "==> API health check failed"
REMOTE

echo "==> Deploy complete. API: http://$VM_IP:3000"
