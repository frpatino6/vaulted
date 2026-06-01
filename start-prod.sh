#!/bin/bash
set -euo pipefail
umask 077

if [ ! -f .env.prod ]; then
  echo "Missing .env.prod" >&2
  exit 1
fi
chmod 600 .env.prod

# Parse .env.prod safely — splits only on FIRST = to preserve URLs with = in values
while IFS= read -r line || [ -n "$line" ]; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line// }" ]] && continue
  key="${line%%=*}"
  value="${line#*=}"
  export "$key=$value"
done < .env.prod

required=(JWT_SECRET JWT_REFRESH_SECRET ENCRYPTION_KEY ENCRYPTION_SALT MONGODB_URI DATABASE_URL REDIS_URL)
missing=()
for var in "${required[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    missing+=("$var")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "ERROR: Missing required env vars in .env.prod:"
  printf '  - %s\n' "${missing[@]}"
  exit 1
fi

docker compose -f docker-compose.prod.yml "$@"
