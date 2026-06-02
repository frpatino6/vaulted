#!/usr/bin/env bash
set -euo pipefail
umask 077

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env.prod"
BACKUP_FILE="$ROOT_DIR/.env.prod.backup.$(date +%Y%m%d-%H%M%S)"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found. Run this script from the deployed Vaulted repo on the VM." >&2
  exit 1
fi

generate_secret() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 64
    return
  fi

  if command -v node >/dev/null 2>&1; then
    node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
    return
  fi

  echo "ERROR: openssl or node is required to generate secrets." >&2
  exit 1
}

set_env_value() {
  local key="$1"
  local value="$2"
  local tmp_file
  tmp_file="$(mktemp)"

  if grep -qE "^${key}=" "$ENV_FILE"; then
    awk -v key="$key" -v value="$value" '
      BEGIN { replaced = 0 }
      $0 ~ "^" key "=" {
        print key "=" value
        replaced = 1
        next
      }
      { print }
      END {
        if (replaced == 0) print key "=" value
      }
    ' "$ENV_FILE" > "$tmp_file"
  else
    cp "$ENV_FILE" "$tmp_file"
    printf '\n%s=%s\n' "$key" "$value" >> "$tmp_file"
  fi

  cat "$tmp_file" > "$ENV_FILE"
  rm -f "$tmp_file"
}

get_env_value() {
  local key="$1"
  grep -E "^${key}=" "$ENV_FILE" | tail -1 | cut -d= -f2-
}

echo "Vaulted production auth/media secret rotation"
echo "Repo: $ROOT_DIR"
echo "Env : $ENV_FILE"
echo ""
echo "This will rotate JWT_SECRET, JWT_REFRESH_SECRET, and MEDIA_JWT_SECRET."
echo "All users will need to log in again. Existing signed media URLs will expire immediately."
echo ""
read -r -p "Continue? Type ROTATE to proceed: " confirm
if [[ "$confirm" != "ROTATE" ]]; then
  echo "Aborted."
  exit 0
fi

cp "$ENV_FILE" "$BACKUP_FILE"
chmod 600 "$BACKUP_FILE"
echo "Backup written: $BACKUP_FILE"

JWT_SECRET_NEW="$(generate_secret)"
JWT_REFRESH_SECRET_NEW="$(generate_secret)"
MEDIA_JWT_PREVIOUS_SECRET="$(get_env_value "MEDIA_JWT_SECRET" || true)"
MEDIA_JWT_SECRET_NEW="$(generate_secret)"

set_env_value "JWT_SECRET" "$JWT_SECRET_NEW"
set_env_value "JWT_REFRESH_SECRET" "$JWT_REFRESH_SECRET_NEW"
if [[ -n "$MEDIA_JWT_PREVIOUS_SECRET" ]]; then
  set_env_value "MEDIA_JWT_PREVIOUS_SECRET" "$MEDIA_JWT_PREVIOUS_SECRET"
fi
set_env_value "MEDIA_JWT_SECRET" "$MEDIA_JWT_SECRET_NEW"
chmod 600 "$ENV_FILE"

echo "Secrets rotated in .env.prod."
echo "Restarting API..."

cd "$ROOT_DIR"
./start-prod.sh down
docker compose -f docker-compose.prod.yml build --no-cache
./start-prod.sh up -d

echo ""
echo "Container status:"
docker compose -f docker-compose.prod.yml ps

echo ""
echo "Recent API logs:"
docker logs vaulted_api --tail 80

echo ""
echo "Done. Verify health:"
echo "  curl -fsS https://api-vaulted.casacam.net/api/health"
