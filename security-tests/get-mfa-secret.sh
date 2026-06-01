#!/usr/bin/env bash
# ============================================================
# ONE-TIME script: set up MFA secret for pentest scripts.
# Run once, saves MFA_SECRET to security-tests/.env
# Never run this again unless you reset MFA entirely.
# ============================================================
set -euo pipefail

API="https://api-vaulted.casacam.net/api"
DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$DIR/.env"

if [[ -f "$ENV_FILE" ]] && grep -q "MFA_SECRET=" "$ENV_FILE" 2>/dev/null; then
  echo "✅ MFA_SECRET already saved in $ENV_FILE"
  echo "   Delete that file if you want to regenerate."
  exit 0
fi

read -rp "Email [owner@test.com]: " EMAIL
EMAIL="${EMAIL:-owner@test.com}"
read -rsp "Password: " PASSWORD
echo ""

echo ""
echo "▶ Logging in..."
LOGIN=$(curl -s -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -c /tmp/mfa-setup-cookies.txt \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
PRE_TOKEN=$(echo "$LOGIN" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])" 2>/dev/null || echo "")
if [[ -z "$PRE_TOKEN" ]]; then
  echo "❌ Login failed. Check credentials."
  exit 1
fi
echo "✅ Login OK"

echo ""
echo "▶ Calling /auth/mfa/setup..."
SETUP=$(curl -s -X POST "$API/auth/mfa/setup" \
  -H "Authorization: Bearer $PRE_TOKEN" \
  -b /tmp/mfa-setup-cookies.txt \
  -c /tmp/mfa-setup-cookies.txt)
SECRET=$(echo "$SETUP" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['secret'])" 2>/dev/null || echo "")
QR_DATA_URL=$(echo "$SETUP" | python3 -c "import sys,json; print(json.load(sys.stdin)['data'].get('qrCodeDataUrl',''))" 2>/dev/null || echo "")

if [[ -z "$SECRET" ]]; then
  echo "❌ Could not get MFA secret from setup response."
  echo "Response: $SETUP"
  exit 1
fi

echo ""
echo "════════════════════════════════════════"
echo "  YOUR NEW MFA SECRET (base32):"
echo ""
echo "  $SECRET"
echo ""
echo "  Add this to your authenticator app NOW"
echo "  (Google Authenticator → + → Enter setup key)"
echo "════════════════════════════════════════"

if [[ -n "$QR_DATA_URL" ]]; then
  QR_FILE="/tmp/vaulted-mfa-qr.png"
  echo "$QR_DATA_URL" | python3 -c "
import sys, base64
data = sys.stdin.read().strip()
if ',' in data:
    data = data.split(',',1)[1]
open('$QR_FILE','wb').write(base64.b64decode(data))
print('QR saved to $QR_FILE')
" 2>/dev/null && echo "  QR image saved to $QR_FILE — open it to scan" || true
fi

echo ""
echo "⚠ You have 10 minutes to scan and enter a code."
read -rp "Enter 6-digit code from your authenticator app: " CODE

echo ""
echo "▶ Verifying..."
VERIFY=$(curl -s -X POST "$API/auth/mfa/verify" \
  -H "Authorization: Bearer $PRE_TOKEN" \
  -H "Content-Type: application/json" \
  -b /tmp/mfa-setup-cookies.txt \
  -d "{\"code\":\"$CODE\"}")
VERIFIED_TOKEN=$(echo "$VERIFY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('accessToken',''))" 2>/dev/null || echo "")

if [[ -n "$VERIFIED_TOKEN" ]]; then
  echo "MFA_SECRET=$SECRET" > "$ENV_FILE"
  echo "✅ MFA verified and secret saved to $ENV_FILE"
  echo ""
  echo "From now on, run the pentest scripts normally:"
  echo "  bash run-all.sh"
  echo "  bash idor-rbac-tests.sh"
  echo ""
  echo "The scripts will load MFA_SECRET from .env automatically."
else
  echo "❌ Verification failed: $VERIFY"
  echo "   Try again or wait 30s for the next code."
  exit 1
fi

rm -f /tmp/mfa-setup-cookies.txt
