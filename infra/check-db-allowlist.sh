#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env.prod}"
EXPECTED_VM_IP="${EXPECTED_VM_IP:-34.57.81.166}"
API_BASE_URL="${API_BASE_URL:-https://api-vaulted.casacam.net}"

read_env_value() {
  local key="$1"
  local line
  if [[ ! -f "$ENV_FILE" ]]; then
    return 0
  fi
  line="$(grep -E "^${key}=" "$ENV_FILE" | tail -1 || true)"
  if [[ -z "$line" ]]; then
    return 0
  fi
  echo "${line#*=}"
}

detect_public_ip() {
  local ip
  ip="$(curl -fsS4 https://ifconfig.me 2>/dev/null || true)"
  if [[ -z "$ip" ]]; then
    ip="$(curl -fsS4 https://icanhazip.com 2>/dev/null | tr -d '[:space:]' || true)"
  fi
  echo "$ip"
}

print_masked_host() {
  local label="$1"
  local value="$2"

  if [[ -z "$value" ]]; then
    echo "$label: not set"
    return
  fi

  case "$value" in
    mongodb+srv://*)
      echo "$label: $(echo "$value" | sed -E 's#^mongodb\+srv://[^@]+@#mongodb+srv://***:***@#; s#\?.*$##')"
      ;;
    postgres://*|postgresql://*)
      echo "$label: $(echo "$value" | sed -E 's#^(postgres(ql)?://)[^@]+@#\1***:***@#; s#\?.*$##')"
      ;;
    rediss://*|redis://*)
      echo "$label: $(echo "$value" | sed -E 's#^(redis(s)?://)[^@]+@#\1***:***@#; s#\?.*$##')"
      ;;
    *)
      echo "$label: set"
      ;;
  esac
}

check_health() {
  local path="$1"
  local url="${API_BASE_URL%/}$path"
  local code

  code="$(curl -k -sS -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || true)"
  if [[ "$code" == "200" ]]; then
    echo "PASS: $url returned 200"
    return 0
  fi

  echo "WARN: $url returned ${code:-no response}"
  return 1
}

echo "Vaulted DB allowlist verification"
echo "Repo: $ROOT_DIR"
echo "Env : $ENV_FILE"
echo ""

public_ip="$(detect_public_ip)"
if [[ -z "$public_ip" ]]; then
  echo "ERROR: could not detect this machine public IPv4. Check outbound network/DNS."
  exit 1
fi

echo "Detected public IPv4: $public_ip"
echo "Expected VM IPv4   : $EXPECTED_VM_IP"

if [[ "$public_ip" == "$EXPECTED_VM_IP" ]]; then
  echo "PASS: public IP matches the expected Vaulted VM IP."
else
  echo "WARN: public IP does not match EXPECTED_VM_IP."
  echo "      Do not use this machine for DB allowlists unless this is the production VM."
fi

echo ""
echo "Provider allowlist entries to configure:"
echo "  MongoDB Atlas : $public_ip/32"
echo "  PostgreSQL    : $public_ip/32 when the provider/plan supports IP restrictions"
echo "  Upstash Redis : $public_ip/32 when the provider/plan supports IP restrictions"

echo ""
if [[ -f "$ENV_FILE" ]]; then
  print_masked_host "MONGODB_URI" "$(read_env_value MONGODB_URI)"
  print_masked_host "DATABASE_URL" "$(read_env_value DATABASE_URL)"
  print_masked_host "REDIS_URL" "$(read_env_value REDIS_URL)"
else
  echo "WARN: $ENV_FILE not found; skipping masked connection summary."
fi

echo ""
echo "API health checks:"
health_ok=0
check_health "/api/health" && health_ok=1
check_health "/health" && health_ok=1

if [[ "$health_ok" -eq 0 ]]; then
  echo "ERROR: API health did not return 200 on /api/health or /health."
  echo "       Check docker logs vaulted_api --tail 100 after each allowlist change."
  exit 1
fi

echo ""
echo "Done. Run this after each provider allowlist change."
