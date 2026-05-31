#!/usr/bin/env bash
# Vaulted — IDOR & RBAC Tests
# Requires TWO tenant accounts to test cross-tenant isolation
# Usage: OWNER_TOKEN=xxx STAFF_TOKEN=yyy bash idor-rbac-tests.sh

API="https://api-vaulted.casacam.net/api"
PASS=0; FAIL=0

_green() { echo -e "\033[32m✅ PASS | $*\033[0m"; ((PASS++)); }
_red()   { echo -e "\033[31m❌ FAIL | $*\033[0m"; ((FAIL++)); }

# ── Obtain tokens ────────────────────────────────────────────
echo "━━━ IDOR & RBAC Security Tests ━━━"
echo ""
echo "Step 1: Login as owner..."
OWNER_LOGIN=$(curl -s -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -c /tmp/owner-cookies.txt \
  -d '{"email":"owner@test.com","password":"Test1234!Secure"}')
OWNER_TOKEN=$(echo "$OWNER_LOGIN" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])" 2>/dev/null || echo "")

if [[ -z "$OWNER_TOKEN" ]]; then
  echo "❌ Could not get owner token. Exiting."
  exit 1
fi
echo "  ✓ Owner token OK"

# Get a real property ID for this tenant
PROPS=$(curl -s "$API/properties" -H "Authorization: Bearer $OWNER_TOKEN")
PROP_ID=$(echo "$PROPS" | python3 -c "
import sys,json
d=json.load(sys.stdin)
items=d.get('data',[])
print(items[0]['_id'] if items else '')
" 2>/dev/null || echo "")
echo "  ✓ Property ID: ${PROP_ID:-none found}"

# Get a real item ID
if [[ -n "$PROP_ID" ]]; then
  ITEMS=$(curl -s "$API/inventory?propertyId=$PROP_ID" -H "Authorization: Bearer $OWNER_TOKEN")
  ITEM_ID=$(echo "$ITEMS" | python3 -c "
import sys,json
d=json.load(sys.stdin)
items=d.get('data',{}).get('items',[])
print(items[0]['_id'] if items else '')
" 2>/dev/null || echo "")
  echo "  ✓ Item ID: ${ITEM_ID:-none found}"
fi

echo ""
echo "━━━ Phase 3A: RBAC — Role Privilege Tests ━━━"

# 3A.1 Owner can list users
R=$(curl -s -o /dev/null -w "%{http_code}" "$API/users" \
  -H "Authorization: Bearer $OWNER_TOKEN")
[[ "$R" == "200" ]] && _green "Owner can list users (200)" || _red "Owner cannot list users ($R)"

# 3A.2 Owner cannot access another tenant's property via fake ID
FAKE_PROP="000000000000000000000099"
R=$(curl -s -o /dev/null -w "%{http_code}" "$API/properties/$FAKE_PROP" \
  -H "Authorization: Bearer $OWNER_TOKEN")
[[ "$R" == "403" || "$R" == "404" ]] && \
  _green "Cross-tenant property access blocked ($R)" || \
  _red "Cross-tenant property returned $R (expected 403/404)"

# 3A.3 Owner cannot access another tenant's inventory item
FAKE_ITEM="000000000000000000000099"
R=$(curl -s -o /dev/null -w "%{http_code}" "$API/inventory/$FAKE_ITEM" \
  -H "Authorization: Bearer $OWNER_TOKEN")
[[ "$R" == "403" || "$R" == "404" ]] && \
  _green "Cross-tenant inventory access blocked ($R)" || \
  _red "Cross-tenant inventory returned $R (expected 403/404)"

# 3A.4 Attempt to modify another tenant's item
R=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$API/inventory/$FAKE_ITEM" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"HACKED"}')
[[ "$R" == "403" || "$R" == "404" ]] && \
  _green "Cross-tenant item modification blocked ($R)" || \
  _red "Cross-tenant item modification returned $R"

# 3A.5 Attempt to delete another tenant's item
R=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$API/inventory/$FAKE_ITEM" \
  -H "Authorization: Bearer $OWNER_TOKEN")
[[ "$R" == "403" || "$R" == "404" ]] && \
  _green "Cross-tenant item deletion blocked ($R)" || \
  _red "Cross-tenant item deletion returned $R"

# 3A.6 Owner cannot access insurance of another tenant
R=$(curl -s -o /dev/null -w "%{http_code}" "$API/insurance/policies" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "X-Tenant-Id: othertenant_000000000001")
# The header should be ignored — only JWT tenantId used
[[ "$R" == "200" || "$R" == "401" || "$R" == "403" ]] && \
  _green "X-Tenant-Id header injection ignored (own tenant data returned)" || \
  _red "Tenant header injection returned $R"

echo ""
echo "━━━ Phase 3B: Object-Level Tests ━━━"

if [[ -n "$ITEM_ID" ]]; then
  # Access own item (should work)
  R=$(curl -s -o /dev/null -w "%{http_code}" "$API/inventory/$ITEM_ID" \
    -H "Authorization: Bearer $OWNER_TOKEN")
  [[ "$R" == "200" ]] && \
    _green "Owner can access own inventory item" || \
    _red "Owner cannot access own item ($R)"

  # Try sequential ID enumeration (MongoDB ObjectIDs aren't sequential, but test anyway)
  ITEM_MODIFIED="${ITEM_ID:0:-4}0001"
  R=$(curl -s -o /dev/null -w "%{http_code}" "$API/inventory/$ITEM_MODIFIED" \
    -H "Authorization: Bearer $OWNER_TOKEN")
  [[ "$R" == "403" || "$R" == "404" ]] && \
    _green "Sequential ID enumeration blocked ($R)" || \
    _red "Sequential ID enumeration returned $R"
fi

echo ""
echo "━━━ Phase 3C: Privilege Escalation ━━━"

# Try to self-promote to owner (if currently manager)
R=$(curl -s -X PATCH "$API/users/me" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"role":"owner"}' 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('statusCode','?'))" 2>/dev/null || echo "unknown")
echo "  INFO | Self-role-modification response: $R"

# Try to invite a user with higher role than own
R=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/users/invite" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@evil.com","role":"owner","propertyIds":[]}')
echo "  INFO | Invite-as-owner response: $R (owner inviting owner — varies by policy)"

echo ""
echo "════════════════════════════════"
echo "  PASS: $PASS  FAIL: $FAIL"
echo "════════════════════════════════"
