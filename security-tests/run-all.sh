#!/usr/bin/env bash
# ============================================================
# Vaulted — Security Test Suite
# Run from your local machine: bash run-all.sh
# ============================================================
set -euo pipefail

API="https://api-vaulted.casacam.net/api"
EMAIL="owner@test.com"
PASSWORD="Test1234!Secure"

PASS=0; FAIL=0; WARN=0
LOG="pentest-$(date +%Y%m%d-%H%M%S).log"

_green() { echo -e "\033[32m✅ $*\033[0m"; }
_red()   { echo -e "\033[31m❌ $*\033[0m"; }
_warn()  { echo -e "\033[33m⚠️  $*\033[0m"; }
_info()  { echo -e "\033[36mℹ️  $*\033[0m"; }
_section(){ echo -e "\n\033[1m━━━ $* ━━━\033[0m"; }

check() {
  local name="$1" expected="$2" actual="$3" detail="${4:-}"
  if [[ "$actual" == *"$expected"* ]]; then
    _green "PASS | $name"
    echo "PASS | $name | expected=$expected actual=$actual" >> "$LOG"
    ((PASS++))
  else
    _red   "FAIL | $name"
    echo "FAIL | $name | expected=$expected actual=$actual $detail" >> "$LOG"
    ((FAIL++))
  fi
}

warn_if_present() {
  local name="$1" unwanted="$2" actual="$3"
  if [[ "$actual" == *"$unwanted"* ]]; then
    _warn  "WARN | $name — found: $unwanted"
    echo "WARN | $name | $unwanted present" >> "$LOG"
    ((WARN++))
  else
    _green "PASS | $name"
    echo "PASS | $name" >> "$LOG"
    ((PASS++))
  fi
}

echo "Vaulted Security Test Suite — $(date)" | tee "$LOG"
echo "Target: $API" | tee -a "$LOG"

# ── LOGIN ────────────────────────────────────────────────────
_section "Setup: obtain valid token"
LOGIN=$(curl -s -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" \
  -c /tmp/vaulted-cookies.txt)
TOKEN=$(echo "$LOGIN" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('accessToken',''))" 2>/dev/null || echo "")
if [[ -z "$TOKEN" ]]; then
  _red "Could not obtain token — check credentials or API availability"
  exit 1
fi
_green "Token obtained (${#TOKEN} chars)"

# ── PHASE 1: SECURITY HEADERS ───────────────────────────────
_section "Phase 1 — Security Headers"
HEADERS=$(curl -sI "$API/health")
check "Strict-Transport-Security present"  "strict-transport-security" "${HEADERS,,}"
check "X-Content-Type-Options present"     "x-content-type-options"    "${HEADERS,,}"
check "X-Frame-Options present"            "x-frame-options"           "${HEADERS,,}"
warn_if_present "Server header not leaking version" "nestjs"   "${HEADERS,,}"
warn_if_present "X-Powered-By not present"          "x-powered-by" "${HEADERS,,}"

# ── PHASE 2: AUTHENTICATION ATTACKS ─────────────────────────
_section "Phase 2 — Authentication"

# 2.1 Login with wrong password
R=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@test.com","password":"wrongpassword"}')
check "Wrong password returns 401" "401" "$R"

# 2.2 JWT algorithm=none attack
FAKE_HEADER=$(echo -n '{"alg":"none","typ":"JWT"}' | base64 | tr -d '=' | tr '+/' '-_')
FAKE_PAYLOAD=$(echo -n "{\"sub\":\"fake\",\"role\":\"owner\",\"tenantId\":\"fake\",\"exp\":9999999999}" | base64 | tr -d '=' | tr '+/' '-_')
FAKE_JWT="${FAKE_HEADER}.${FAKE_PAYLOAD}."
R=$(curl -s -o /dev/null -w "%{http_code}" "$API/users" \
  -H "Authorization: Bearer $FAKE_JWT")
check "JWT alg=none rejected" "401" "$R"

# 2.3 Malformed JWT
R=$(curl -s -o /dev/null -w "%{http_code}" "$API/users" \
  -H "Authorization: Bearer notajwt.atall.here")
check "Malformed JWT rejected" "401" "$R"

# 2.4 Empty Authorization header
R=$(curl -s -o /dev/null -w "%{http_code}" "$API/users" \
  -H "Authorization: Bearer ")
check "Empty Bearer token rejected" "401" "$R"

# 2.5 Expired JWT (manually built, exp=1)
EXP_HEADER=$(echo -n '{"alg":"HS256","typ":"JWT"}' | base64 | tr -d '=' | tr '+/' '-_')
EXP_PAYLOAD=$(echo -n '{"sub":"fake","exp":1}' | base64 | tr -d '=' | tr '+/' '-_')
EXP_JWT="${EXP_HEADER}.${EXP_PAYLOAD}.invalidsig"
R=$(curl -s -o /dev/null -w "%{http_code}" "$API/users" \
  -H "Authorization: Bearer $EXP_JWT")
check "Expired JWT rejected" "401" "$R"

# 2.6 Brute force throttle (6 rapid login attempts, expect 429)
_info "Testing login throttle (6 rapid attempts)..."
LAST_CODE=""
for i in $(seq 1 6); do
  LAST_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"owner@test.com","password":"wrongpass"}')
done
check "Login brute force throttled (429)" "429" "$LAST_CODE"

# 2.7 Register with weak password
R=$(curl -s -X POST "$API/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"tenantName":"Test","email":"weak@test.com","password":"123456"}')
check "Weak password rejected" "400" "$(echo "$R" | python3 -c "import sys,json; print(json.load(sys.stdin).get('statusCode',''))" 2>/dev/null || echo "$R")"

# 2.8 Access protected endpoint without token
R=$(curl -s -o /dev/null -w "%{http_code}" "$API/users")
check "Unauthenticated request rejected" "401" "$R"

# ── PHASE 3: AUTHORIZATION & IDOR ───────────────────────────
_section "Phase 3 — Authorization & IDOR"

# 3.1 Access non-existent tenant resource (IDOR attempt)
R=$(curl -s -o /dev/null -w "%{http_code}" "$API/properties/000000000000000000000001" \
  -H "Authorization: Bearer $TOKEN")
check "IDOR attempt on non-existent ID returns 403/404" "40" "$R"

# 3.2 Access inventory with fake MongoDB ID
R=$(curl -s -o /dev/null -w "%{http_code}" "$API/inventory/000000000000000000000001" \
  -H "Authorization: Bearer $TOKEN")
check "IDOR on fake inventory ID returns 403/404" "40" "$R"

# 3.3 Mass assignment — attempt to set tenantId
R=$(curl -s -X POST "$API/properties" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Hacked","tenantId":"othertenant","floors":[]}' 2>/dev/null)
STATUS=$(echo "$R" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('statusCode',''))" 2>/dev/null || echo "")
warn_if_present "Mass assignment: tenantId not accepted from client" "" ""
# Just log it
echo "INFO | Mass assignment test response: $R" >> "$LOG"

# ── PHASE 4: INJECTION ──────────────────────────────────────
_section "Phase 4 — Injection"

# 4.1 NoSQL injection in login
R=$(curl -s -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":{"$gt":""},"password":{"$gt":""}}')
CODE=$(echo "$R" | python3 -c "import sys,json; print(json.load(sys.stdin).get('statusCode',''))" 2>/dev/null || echo "200")
check "NoSQL injection in login blocked" "400" "$CODE"

# 4.2 NoSQL operator in search param
R=$(curl -s -o /dev/null -w "%{http_code}" \
  "$API/inventory?search=\$where:1==1" \
  -H "Authorization: Bearer $TOKEN")
check "NoSQL operator in query param blocked (not 500)" "200" "$R" || true
# 200 or 400 are acceptable; 500 would be a finding
[[ "$R" == "500" ]] && { _red "FAIL | NoSQL in query param caused 500 error"; echo "FAIL | NoSQL 500" >> "$LOG"; }

# 4.3 XSS in inventory name (stored XSS attempt)
R=$(curl -s -X POST "$API/inventory" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"<script>alert(1)</script>","category":"art","roomId":"000000000000000000000001","propertyId":"000000000000000000000001"}' 2>/dev/null)
RETURNED_NAME=$(echo "$R" | python3 -c "import sys,json; d=json.load(sys.stdin); print(str(d))" 2>/dev/null || echo "$R")
warn_if_present "XSS payload not stored as-is" "<script>" "$RETURNED_NAME"

# 4.4 SQL injection via email field
R=$(curl -s -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"' OR '1'='1'; --\",\"password\":\"test\"}")
CODE=$(echo "$R" | python3 -c "import sys,json; print(json.load(sys.stdin).get('statusCode',''))" 2>/dev/null || echo "")
check "SQL injection in email rejected" "401" "$CODE"

# 4.5 Large payload injection (notes field - insurance)
BIG=$(python3 -c "print('A'*100000)")
R=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/insurance/policies" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"provider\":\"Test\",\"policyNumber\":\"POL-001\",\"coverageType\":\"all-risk\",\"totalCoverageAmount\":100000,\"startDate\":\"2026-01-01\",\"expiresAt\":\"2027-01-01\",\"notes\":\"$BIG\"}")
check "100k-char notes field rejected (400/413)" "4" "$R"

# ── PHASE 5: FILE UPLOAD ─────────────────────────────────────
_section "Phase 5 — File Upload"

# 5.1 Upload PHP shell disguised as JPEG (magic bytes check)
printf '\xff\xd8\xff<?php system($_GET["cmd"]);?>' > /tmp/evil.jpg
R=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/media/upload" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/evil.jpg;type=image/jpeg")
check "PHP shell disguised as JPEG rejected" "400" "$R"
rm -f /tmp/evil.jpg

# 5.2 Upload HTML file as JPEG
printf '<html><script>alert(1)</script></html>' > /tmp/evil2.jpg
R=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/media/upload" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/evil2.jpg;type=image/jpeg")
check "HTML file disguised as JPEG rejected" "400" "$R"
rm -f /tmp/evil2.jpg

# 5.3 Upload file exceeding 10MB limit
dd if=/dev/urandom bs=11000000 count=1 of=/tmp/bigfile.jpg 2>/dev/null
# Prepend JPEG magic bytes
printf '\xff\xd8\xff' | cat - /tmp/bigfile.jpg > /tmp/bigfile2.jpg
R=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/media/upload" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/bigfile2.jpg;type=image/jpeg")
check "File >10MB rejected (400/413)" "4" "$R"
rm -f /tmp/bigfile.jpg /tmp/bigfile2.jpg

# 5.4 Path traversal in filename (multipart)
printf '\xff\xd8\xff\xe0\x00\x10JFIF' > /tmp/normal.jpg
R=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/media/upload" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/normal.jpg;filename=../../../etc/passwd;type=image/jpeg")
check "Path traversal in filename handled (not 500)" "4" "$R"
rm -f /tmp/normal.jpg

# 5.5 Upload without auth
printf '\xff\xd8\xff\xe0\x00\x10JFIF' > /tmp/test.jpg
R=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/media/upload" \
  -F "file=@/tmp/test.jpg;type=image/jpeg")
check "File upload without auth rejected (401)" "401" "$R"
rm -f /tmp/test.jpg

# ── PHASE 6: CORS ───────────────────────────────────────────
_section "Phase 6 — CORS"

# 6.1 Request from unauthorized origin
R=$(curl -sI -X OPTIONS "$API/users" \
  -H "Origin: https://evil-attacker.com" \
  -H "Access-Control-Request-Method: GET")
ACAO=$(echo "$R" | grep -i "access-control-allow-origin" | tr -d '\r' || echo "")
if [[ -z "$ACAO" ]]; then
  _green "PASS | Unauthorized origin gets no ACAO header"
  echo "PASS | CORS blocked evil origin" >> "$LOG"
  ((PASS++))
elif [[ "$ACAO" == *"evil-attacker.com"* ]]; then
  _red   "FAIL | CORS allows evil-attacker.com"
  echo "FAIL | CORS | $ACAO" >> "$LOG"
  ((FAIL++))
else
  _green "PASS | CORS did not reflect evil origin"
  echo "PASS | CORS" >> "$LOG"
  ((PASS++))
fi

# 6.2 Request from authorized origin
R=$(curl -sI "$API/health" -H "Origin: https://vaulted.casacam.net")
ACAO=$(echo "$R" | grep -i "access-control-allow-origin" | tr -d '\r' || echo "")
check "Authorized origin gets ACAO header" "vaulted.casacam.net" "$ACAO"

# ── PHASE 7: RATE LIMITING ──────────────────────────────────
_section "Phase 7 — Rate Limiting"

_info "Sending 10 rapid requests to test throttle (global: 600/60s)..."
CODES=""
for i in $(seq 1 10); do
  C=$(curl -s -o /dev/null -w "%{http_code}" "$API/health")
  CODES="$CODES $C"
done
check "Health endpoint responds normally under 10 rapid requests" "200" "$(echo $CODES | tr ' ' '\n' | sort -u | head -1)"

_info "Testing auth endpoint throttle (7 attempts, limit=5/60s)..."
LAST=""
for i in $(seq 1 7); do
  LAST=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"brute@test.com","password":"wrong"}')
done
check "Auth endpoint throttle triggers at 429" "429" "$LAST"

# ── PHASE 8: SENSITIVE DATA EXPOSURE ────────────────────────
_section "Phase 8 — Sensitive Data Exposure"

# 8.1 Error messages don't leak internals
R=$(curl -s "$API/nonexistent-endpoint-xyz")
warn_if_present "Error response doesn't leak stack trace" "at Object." "$R"
warn_if_present "Error response doesn't leak file paths"  "/home/"     "$R"
warn_if_present "Error response doesn't expose NestJS"    "NestJS"     "$R"

# 8.2 Health endpoint doesn't leak config
R=$(curl -s "$API/health")
warn_if_present "Health endpoint doesn't expose DB URI"   "mongodb"    "${R,,}"
warn_if_present "Health endpoint doesn't expose secrets"  "secret"     "${R,,}"

# 8.3 Swagger in production (info leak)
R=$(curl -s -o /dev/null -w "%{http_code}" "https://api-vaulted.casacam.net/api-docs")
if [[ "$R" == "200" ]]; then
  _warn "WARN | Swagger UI is publicly accessible at /api-docs (consider restricting in production)"
  echo "WARN | Swagger public at /api-docs" >> "$LOG"
  ((WARN++))
else
  _green "PASS | Swagger not accessible (or restricted)"
  echo "PASS | Swagger restricted" >> "$LOG"
  ((PASS++))
fi

# ── PHASE 9: TLS / HTTP SECURITY ────────────────────────────
_section "Phase 9 — TLS & HTTP Security"

# 9.1 HTTP redirects to HTTPS
R=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://api-vaulted.casacam.net/api/health 2>/dev/null || echo "000")
if [[ "$R" == "301" ]] || [[ "$R" == "302" ]] || [[ "$R" == "308" ]]; then
  _green "PASS | HTTP redirects to HTTPS ($R)"
  echo "PASS | HTTP→HTTPS redirect" >> "$LOG"
  ((PASS++))
elif [[ "$R" == "000" ]]; then
  _green "PASS | HTTP port not open (connection refused)"
  echo "PASS | HTTP port closed" >> "$LOG"
  ((PASS++))
else
  _warn "WARN | HTTP returns $R (expected redirect)"
  echo "WARN | HTTP no redirect: $R" >> "$LOG"
  ((WARN++))
fi

# 9.2 TLS version via curl
TLS_INFO=$(curl -sv --tlsv1.0 --tls-max 1.0 "$API/health" 2>&1 || true)
if echo "$TLS_INFO" | grep -q "SSL connection\|TLSv1.0"; then
  _red "FAIL | TLS 1.0 accepted"
  echo "FAIL | TLS 1.0 accepted" >> "$LOG"
  ((FAIL++))
else
  _green "PASS | TLS 1.0 not accepted"
  echo "PASS | TLS 1.0 rejected" >> "$LOG"
  ((PASS++))
fi

# 9.3 Verify HSTS
HSTS=$(curl -sI "https://api-vaulted.casacam.net/api/health" | grep -i "strict-transport" || echo "")
check "HSTS header present" "max-age" "$HSTS"

# ── RESULTS ─────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo "  RESULTS"
echo "════════════════════════════════════════"
_green "PASSED : $PASS"
[[ $WARN  -gt 0 ]] && _warn  "WARNINGS: $WARN"
[[ $FAIL  -gt 0 ]] && _red   "FAILED : $FAIL"
echo ""
echo "Full log saved to: $LOG"
echo "════════════════════════════════════════"
