# Vaulted — Security Test Suite

Generated: 2026-05-31  
Target: https://api-vaulted.casacam.net

## Prerequisites

```bash
# macOS
brew install curl python3 node

# Linux
apt-get install curl python3 nodejs npm
```

## Run All Tests (5 min)

```bash
cd security-tests
bash run-all.sh
```

Results saved to `pentest-YYYYMMDD-HHMMSS.log`

## WebSocket Tests (1 min)

```bash
npm install socket.io-client

# Get a token first
export VAULTED_TOKEN=$(curl -s -X POST https://api-vaulted.casacam.net/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@test.com","password":"Test1234!Secure"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])")

node websocket-tests.js
```

## IDOR & RBAC Tests (2 min)

```bash
bash idor-rbac-tests.sh
```

## What Each Script Tests

| Script | Phases | Tests |
|--------|--------|-------|
| `run-all.sh` | 1,2,4,5,6,7,8,9 | Headers, Auth, Injection, Upload, CORS, Rate Limit, TLS |
| `websocket-tests.js` | 6 (WS) | WebSocket auth, token attacks, room isolation |
| `idor-rbac-tests.sh` | 3 | Cross-tenant IDOR, RBAC, privilege escalation |

## Expected Results

All tests should PASS. Any FAIL is a real finding to fix.
WARNINGs are informational (e.g., Swagger publicly accessible).
