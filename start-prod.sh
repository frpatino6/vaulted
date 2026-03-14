#!/bin/bash
set -e

# Parse .env.prod safely (handles URLs with special chars)
while IFS='=' read -r key value || [ -n "$key" ]; do
  [[ "$key" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${key// }" ]] && continue
  export "$key=$value"
done < .env.prod

docker compose -f docker-compose.prod.yml "$@"
