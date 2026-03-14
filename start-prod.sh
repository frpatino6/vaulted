#!/bin/bash
set -e

# Parse .env.prod safely — splits only on FIRST = to preserve URLs with = in values
while IFS= read -r line || [ -n "$line" ]; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line// }" ]] && continue
  key="${line%%=*}"
  value="${line#*=}"
  export "$key=$value"
done < .env.prod

docker compose -f docker-compose.prod.yml "$@"
