#!/usr/bin/env bash
set -euo pipefail
umask 077

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env.prod}"
EMAIL="${1:-}"
YES="${2:-}"

if [[ -z "$EMAIL" ]]; then
  echo "Usage: $0 user@example.com [--yes]" >&2
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found. Run this from the deployed Vaulted repo on the VM." >&2
  exit 1
fi

while IFS= read -r line || [[ -n "$line" ]]; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line// }" ]] && continue
  key="${line%%=*}"
  value="${line#*=}"
  export "$key=$value"
done < "$ENV_FILE"

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "ERROR: DATABASE_URL is missing in $ENV_FILE." >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is required." >&2
  exit 1
fi

echo "Vaulted MFA reset"
echo "User: $EMAIL"
echo ""
echo "This will clear mfa_secret and set mfa_enabled=false."
echo "The user must log in again and enroll a new authenticator code."
echo ""

if [[ "$YES" != "--yes" ]]; then
  read -r -p "Continue? Type RESET-MFA to proceed: " confirm
  if [[ "$confirm" != "RESET-MFA" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

docker run --rm \
  -e "DATABASE_URL=$DATABASE_URL" \
  postgres:16-alpine \
  psql "$DATABASE_URL" \
    -v "email=$EMAIL" <<'SQL'
UPDATE users
SET mfa_secret = NULL,
    mfa_enabled = false,
    updated_at = NOW()
WHERE lower(email) = lower(:'email')
RETURNING id, email, role, mfa_enabled;
SQL

echo ""
echo "Done. Ask the user to log in again. The app should show MFA setup QR/secret."
