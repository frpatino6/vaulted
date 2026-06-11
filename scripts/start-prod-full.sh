#!/usr/bin/env bash
# start-prod-full.sh — Wrapper for fullstack production compose
# Identical to start-prod.sh but targets docker-compose-fullstack.prod.yml
set -euo pipefail

ENV_FILE=".env.prod"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found. Run: ./infra/upload-env.sh"
  exit 1
fi

# Validate required vars are set (non-empty)
REQUIRED=(
  JWT_SECRET JWT_REFRESH_SECRET ENCRYPTION_KEY ENCRYPTION_SALT
  MONGO_ROOT_USER MONGO_ROOT_PASSWORD MONGO_APP_USER MONGO_APP_PASSWORD
  POSTGRES_USER POSTGRES_PASSWORD
  REDIS_PASSWORD REDIS_ADMIN_SUFFIX
  BACKUP_ENCRYPTION_KEY
  GOOGLE_GENAI_API_KEY
)
missing=()
while IFS= read -r line; do
  [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
  export "${line?}"
done < "$ENV_FILE"

for var in "${REQUIRED[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    missing+=("$var")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "ERROR: Missing required env vars in $ENV_FILE:"
  printf '  - %s\n' "${missing[@]}"
  exit 1
fi

chmod +x infra/backup/run-backup.sh

docker compose -f docker-compose-fullstack.prod.yml --env-file "$ENV_FILE" "$@"
