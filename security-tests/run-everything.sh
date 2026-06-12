#!/usr/bin/env bash
# ============================================================
# Vaulted — Master Security Test Orchestrator
# Runs all three test suites and produces a unified report.
#
# Usage:  bash run-everything.sh
# Prereq: run get-mfa-secret.sh once first (saves MFA_SECRET to .env)
# ============================================================
set -uo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
API="https://api-vaulted.casacam.net/api"
LOG="pentest-all-$(date +%Y%m%d-%H%M%S).log"

RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; CYAN='\033[36m'; BOLD='\033[1m'; RESET='\033[0m'

# ── Helpers ───────────────────────────────────────────────────
_banner() { echo -e "\n${BOLD}${CYAN}$*${RESET}"; }
_ok()     { echo -e "${GREEN}✅ $*${RESET}"; }
_err()    { echo -e "${RED}❌ $*${RESET}"; }
_warn()   { echo -e "${YELLOW}⚠  $*${RESET}"; }
_info()   { echo -e "   ℹ  $*"; }

# parse_counter <output> <label>   — extracts a number from lines like "PASS: 87"
parse_counter() {
  local output="$1" label="$2"
  echo "$output" | grep -oiE "${label}:[[:space:]]*[0-9]+" | grep -oE '[0-9]+' | tail -1 || echo "0"
}

# ── Prerequisites ─────────────────────────────────────────────
_banner "Checking prerequisites…"
MISSING=()
for cmd in curl python3 node npm; do
  if ! command -v "$cmd" &>/dev/null; then MISSING+=("$cmd"); fi
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  _err "Missing required tools: ${MISSING[*]}"
  echo "Install them and re-run."
  exit 1
fi
_ok "curl, python3, node, npm — all present"

# ── Load .env ─────────────────────────────────────────────────
[[ -f "$DIR/.env" ]] && source "$DIR/.env"
MFA_SECRET="${MFA_SECRET:-}"
MFA_LIVE_CODE="${MFA_LIVE_CODE:-}"
if [[ -z "$MFA_SECRET" && -z "$MFA_LIVE_CODE" ]]; then
  _warn "MFA_SECRET/MFA_LIVE_CODE not set. Run get-mfa-secret.sh first for full coverage."
  _warn "WebSocket tests and some pentest phases will use a pre-MFA token."
fi

# ── npm install (before auth so token is fresh when tests run) ─
if [[ ! -d "$DIR/node_modules" ]]; then
  _banner "Installing Node.js dependencies…"
  npm --prefix "$DIR" install --silent
fi

# ── Login + MFA → get FULL_TOKEN for websocket-tests.js ───────
_banner "Authenticating (needed for websocket-tests.js)…"

json_val() { echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d$2)" 2>/dev/null || echo ""; }

totp_code() {
  python3 - <<PYEOF
import hmac, hashlib, struct, time, base64, sys
s = '${MFA_SECRET}'.upper().replace(' ','')
if not s: sys.exit(1)
key = base64.b32decode(s + '=' * ((8 - len(s) % 8) % 8))
msg = struct.pack('>Q', int(time.time()) // 30)
h = hmac.new(key, msg, hashlib.sha1).digest()
o = h[-1] & 0xf
print(str((struct.unpack('>I', h[o:o+4])[0] & 0x7fffffff) % 1000000).zfill(6))
PYEOF
}

login_attempt() {
  curl -s -X POST "$API/auth/login" \
    -H "Content-Type: application/json" \
    -c /tmp/vaulted-master-cookies.txt \
    -d '{"email":"owner@test.com","password":"Test1234!Secure"}'
}

LOGIN_RESP=$(login_attempt)
TOKEN=$(json_val "$LOGIN_RESP" "['data']['accessToken']")
ERR_CODE=$(json_val "$LOGIN_RESP" ".get('error',{}).get('statusCode',0)")

RETRIES=0
while [[ -z "$TOKEN" && "$ERR_CODE" == "429" && $RETRIES -lt 2 ]]; do
  _warn "Login rate-limited (429). Waiting 65s for throttle window to clear…"
  for i in $(seq 65 -5 0); do printf "\r   %ds remaining…" "$i"; sleep 5; done
  echo ""
  LOGIN_RESP=$(login_attempt)
  TOKEN=$(json_val "$LOGIN_RESP" "['data']['accessToken']")
  ERR_CODE=$(json_val "$LOGIN_RESP" ".get('error',{}).get('statusCode',0)")
  RETRIES=$((RETRIES+1))
done

MFA_REQ=$(json_val "$LOGIN_RESP" ".get('data',{}).get('mfaRequired',False)")

if [[ -z "$TOKEN" ]]; then
  _err "Login failed — check API availability and credentials."
  echo "Response: $LOGIN_RESP"
  exit 1
fi

FULL_TOKEN="$TOKEN"
if [[ "$MFA_REQ" == "True" || "$MFA_REQ" == "true" ]]; then
  if [[ -n "$MFA_SECRET" ]]; then
    MFA_CODE=$(totp_code 2>/dev/null || echo "")
  elif [[ -n "$MFA_LIVE_CODE" ]]; then
    MFA_CODE="$MFA_LIVE_CODE"
  elif [[ -t 0 ]]; then
    read -rp "MFA required. Enter current 6-digit code from your authenticator app: " MFA_CODE
  else
    MFA_CODE=""
  fi
  if [[ -n "$MFA_CODE" ]]; then
    MFA_RESP=$(curl -s -X POST "$API/auth/mfa/verify" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -b /tmp/vaulted-master-cookies.txt \
      -c /tmp/vaulted-master-cookies.txt \
      -d "{\"code\":\"$MFA_CODE\"}")
    VERIFIED=$(json_val "$MFA_RESP" ".get('data',{}).get('accessToken','')")
    if [[ -n "$VERIFIED" ]]; then
      FULL_TOKEN="$VERIFIED"
      _ok "MFA verified — full-access token ready"
    else
      _warn "MFA verification failed (response: $MFA_RESP) — using pre-MFA token"
    fi
  else
    _warn "MFA required but MFA_SECRET/MFA_LIVE_CODE missing — using pre-MFA token for websocket tests"
  fi
else
  _ok "Token obtained (no MFA required)"
fi

# ═══════════════════════════════════════════════════════════════
# RUN SUITE 1 — idor-rbac-tests.sh  (before pentest-full bruteforce)
# ═══════════════════════════════════════════════════════════════
_banner "Suite 1/3 — idor-rbac-tests.sh (IDOR + RBAC)"
set +e
OWNER_TOKEN="$FULL_TOKEN" bash "$DIR/idor-rbac-tests.sh" 2>&1 | tee /tmp/vaulted-suite1.out
IDOR_EXIT=${PIPESTATUS[0]}
set -e
IDOR_OUT=$(cat /tmp/vaulted-suite1.out)
cat /tmp/vaulted-suite1.out >> "$LOG"

P2_PASS=$(parse_counter "$IDOR_OUT" "PASS")
P2_FAIL=$(parse_counter "$IDOR_OUT" "FAIL")

# ═══════════════════════════════════════════════════════════════
# RUN SUITE 2 — pentest-full.sh  (last because brute-force phase
#               triggers auth rate-limiting for subsequent logins)
# ═══════════════════════════════════════════════════════════════
_banner "Suite 2/3 — pentest-full.sh (17 phases)"
set +e
FULL_TOKEN="$FULL_TOKEN" bash "$DIR/scripts/pentest-full.sh" 2>&1 | tee /tmp/vaulted-suite2.out
PENTEST_EXIT=${PIPESTATUS[0]}
set -e
PENTEST_OUT=$(cat /tmp/vaulted-suite2.out)
cat /tmp/vaulted-suite2.out >> "$LOG"

P1_PASS=$(parse_counter "$PENTEST_OUT" "PASS")
P1_FAIL=$(parse_counter "$PENTEST_OUT" "FAIL")
P1_WARN=$(parse_counter "$PENTEST_OUT" "WARN")
P1_SKIP=$(parse_counter "$PENTEST_OUT" "SKIP")

# ═══════════════════════════════════════════════════════════════
# RUN SUITE 3 — websocket-tests.js
# ═══════════════════════════════════════════════════════════════
_banner "Suite 3/3 — websocket-tests.js (WebSocket security)"
set +e
VAULTED_TOKEN="$FULL_TOKEN" node "$DIR/websocket-tests.js" 2>&1 | tee /tmp/vaulted-suite3.out
WS_EXIT=${PIPESTATUS[0]}
set -e
WS_OUT=$(cat /tmp/vaulted-suite3.out)
cat /tmp/vaulted-suite3.out >> "$LOG"

P3_PASS=$(parse_counter "$WS_OUT" "pass")
P3_FAIL=$(parse_counter "$WS_OUT" "fail")

# ═══════════════════════════════════════════════════════════════
# UNIFIED SUMMARY
# ═══════════════════════════════════════════════════════════════
TOTAL_PASS=$(( P1_PASS + P2_PASS + P3_PASS ))
TOTAL_FAIL=$(( P1_FAIL + P2_FAIL + P3_FAIL ))
TOTAL_WARN=$(( P1_WARN ))
TOTAL_SKIP=$(( P1_SKIP ))

printf "\n${CYAN}${BOLD}"
printf "╔══════════════════════════════════════════════════════════╗\n"
printf "║          Vaulted — Full Security Test Results            ║\n"
printf "╠══════════════════════════════════════════════════════════╣\n"
printf "║  %-24s  PASS: %3s  FAIL: %3s  WARN: %3s  SKIP: %3s  ║\n" \
  "pentest-full.sh" "$P1_PASS" "$P1_FAIL" "$P1_WARN" "$P1_SKIP"
printf "║  %-24s  PASS: %3s  FAIL: %3s                    ║\n" \
  "idor-rbac-tests.sh" "$P2_PASS" "$P2_FAIL"
printf "║  %-24s  PASS: %3s  FAIL: %3s                    ║\n" \
  "websocket-tests.js" "$P3_PASS" "$P3_FAIL"
printf "╠══════════════════════════════════════════════════════════╣\n"
printf "║  %-24s  PASS: %3s  FAIL: %3s  WARN: %3s  SKIP: %3s  ║\n" \
  "TOTAL" "$TOTAL_PASS" "$TOTAL_FAIL" "$TOTAL_WARN" "$TOTAL_SKIP"
printf "╚══════════════════════════════════════════════════════════╝\n"
printf "${RESET}"

echo ""
if (( TOTAL_FAIL > 0 )); then
  _err "$TOTAL_FAIL test(s) FAILED — remediation required before production."
  echo -e "Log saved: ${BOLD}$LOG${RESET}"
  exit 1
else
  _ok "All tests passed.$([ "$TOTAL_WARN" -gt 0 ] && echo " Review $TOTAL_WARN WARN item(s) above." || echo "")"
  echo -e "Log saved: ${BOLD}$LOG${RESET}"
  exit 0
fi
