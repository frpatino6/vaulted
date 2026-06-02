# Vaulted — Infrastructure & Deployment Guide

## Architecture Overview

```
                  Internet
                     |
              [Dynu DNS]
      api-vaulted.casacam.net
              A → 34.57.81.166
                     |
          [GCP VM: tennis-backend]
           e2-micro / us-central1-c
           IP: 34.57.81.166
                     |
          [Docker: frpatino6-caddy-1]
           Caddy reverse proxy
           Ports 80 / 443 (public)
           SSL via Let's Encrypt
                     |
          [Docker: vaulted_api]
           NestJS — internal port 3000
           Network: frpatino6_default
                     |
         ┌───────────┼───────────┐
         |           |           |
  [MongoDB Atlas] [Neon PG]  [Upstash Redis]
   M0 free tier  free tier   free tier
   (cloud)       + pgvector   (TLS rediss://)

Web App:
  Flutter build → Firebase Hosting
  https://vaulted-prod-2026.web.app
  API calls → https://api-vaulted.casacam.net/api/
```

---

## Services and URLs

| Service | URL / Location | Notes |
|---|---|---|
| API (production) | `https://api-vaulted.casacam.net` | NestJS on port 3000 internally |
| Health check | `https://api-vaulted.casacam.net/health` | Returns DB status |
| Web app | `https://vaulted-prod-2026.web.app` | Flutter web on Firebase Hosting |
| MongoDB | MongoDB Atlas M0 | `mycoffecluster.yerjpro.mongodb.net` |
| PostgreSQL | Neon.tech (free) | Includes pgvector extension |
| Redis | Upstash (free) | TLS required, `rediss://` scheme |
| VM | GCP `tennis-backend` | e2-micro, us-central1-c |
| DNS | Dynu (`casacam.net`) | A record → 34.57.81.166 |

---

## VM Details

- **Name**: tennis-backend
- **Project**: tennis-management-fcd54
- **Zone**: us-central1-c
- **Machine type**: e2-micro (free tier)
- **External IP**: 34.57.81.166
- **Swap**: 2GB at `/swapfile` (required — Docker builds need extra memory)
- **OS**: Linux (Debian)
- **Docker**: Compose v2

The VM is shared with `tennis-backend` (unrelated app). Both apps share the same Caddy container (`frpatino6-caddy-1`) for reverse proxying.

---

## Key Files in the Repository

```
docker-compose.prod.yml     Production compose: API only, joins frpatino6_default network
docker-compose.dev.yml      Local dev: API + MongoDB + PostgreSQL + Redis all in Docker
start-prod.sh               Safe wrapper: parses .env.prod line-by-line, then runs docker compose
.env.prod                   NOT in git (gitignored) — real secrets
.env.prod.example           Template for .env.prod
apps/api/Dockerfile.prod    Multi-stage build: builder + runner stages
infra/build-web.sh          Builds Flutter web + deploys to Firebase Hosting
infra/Caddyfile             Caddy config with both domains (copy to VM at ~/Caddyfile)
infra/upload-env.sh         Uploads .env.prod from local machine to VM via gcloud scp
```

---

## Environment Variables

The `.env.prod` file is never committed to git. Create it from `.env.prod.example` and fill in all values.

---

## Database Network Allowlist

Production uses managed cloud databases. Do not move production MongoDB/PostgreSQL/Redis into the API Docker host. For Vaulted, the safer production posture is:

- API in Docker on the GCP VM.
- MongoDB Atlas, PostgreSQL, and Redis in managed cloud services.
- Each database accepts traffic only from the Vaulted VM public IP when the provider/plan supports IP restrictions.

### Current production allowlist target

Use the VM public IPv4 only:

```text
34.57.81.166/32
```

If the VM IP changes, update every database allowlist before restarting the API. A dynamic VM IP is not acceptable for production because a VM restart can silently break database connectivity or expose the DB allowlist to the wrong machine later.

### Reserve or confirm the static GCP IP

Run from a machine with GCP access:

```bash
gcloud compute instances describe tennis-backend \
  --zone us-central1-c \
  --project tennis-management-fcd54 \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

The output must be `34.57.81.166`. If the address is ephemeral in GCP, reserve it as a static external IPv4 before closing database allowlists.

### Verify from the VM

Run this from the deployed repo on the production VM:

```bash
chmod +x infra/check-db-allowlist.sh
./infra/check-db-allowlist.sh
```

The script prints the public IPv4 that providers must allow, shows masked DB connection targets, and checks API health on both `/api/health` and `/health`.

### Provider order

Change one provider at a time and verify API health after each change.

1. MongoDB Atlas
   - Network Access: remove `0.0.0.0/0` or broad ranges.
   - Add `34.57.81.166/32`.
   - Keep the application DB user scoped to the `vaulted` database with least privilege.
   - Run `./infra/check-db-allowlist.sh`.

2. PostgreSQL
   - If the provider/plan supports IP allowlisting, add `34.57.81.166/32` and remove broad ranges.
   - Keep TLS required in `DATABASE_URL`.
   - If strict IP allowlist is not available on the current plan, treat that as a residual risk and prioritize moving PostgreSQL to a plan/provider that supports network restrictions.
   - Run `./infra/check-db-allowlist.sh`.

3. Redis
   - Use `rediss://` only.
   - If the provider/plan supports IP allowlisting, add `34.57.81.166/32` and remove broad ranges.
   - If strict IP allowlist is not available, rotate the Redis credential and track the missing allowlist as residual risk until the provider/plan is upgraded.
   - Run `./infra/check-db-allowlist.sh`.

### Failure handling

If the API health check fails after a provider change:

```bash
docker logs vaulted_api --tail 100
```

Then restore the last known working allowlist for that provider. Do not change the next provider until the API is healthy again.

---

### Generating secrets

```bash
# JWT secrets
openssl rand -hex 64   # use for JWT_SECRET, JWT_REFRESH_SECRET, and MEDIA_JWT_SECRET

# Encryption key
openssl rand -hex 32   # use for ENCRYPTION_KEY
openssl rand -hex 32   # use for ENCRYPTION_SALT
```

### Key variables

| Variable | Source | Notes |
|---|---|---|
| `JWT_SECRET` | `openssl rand -hex 64` | Access token signing |
| `JWT_REFRESH_SECRET` | `openssl rand -hex 64` | Refresh token signing |
| `MEDIA_JWT_SECRET` | `openssl rand -hex 64` | Private media token signing |
| `ENCRYPTION_KEY` | `openssl rand -hex 32` | AES-256 data encryption |
| `ENCRYPTION_SALT` | `openssl rand -hex 32` | Mandatory KDF salt; rotate only with infra/re-encrypt-salt.js |
| `MONGODB_URI` | MongoDB Atlas | Copy connection string from Atlas dashboard |
| `DATABASE_URL` | Neon.tech | Include `?sslmode=require` at the end |
| `REDIS_URL` | Upstash | Use `rediss://` (TLS) format |
| `GOOGLE_GENAI_API_KEY` | Google AI Studio | For AI features |

### Rotate auth/media signing secrets on the VM

Run from the deployed repo on the production VM:

```bash
chmod +x infra/rotate-prod-auth-secrets.sh
./infra/rotate-prod-auth-secrets.sh
```

The script backs up `.env.prod`, rotates `JWT_SECRET`, `JWT_REFRESH_SECRET`, and `MEDIA_JWT_SECRET`, stores the old media secret as `MEDIA_JWT_PREVIOUS_SECRET`, rebuilds the API, and restarts the container. All users must log in again after this rotation. Existing signed media URLs continue working during the temporary previous-secret window.

After 24-48 hours, remove `MEDIA_JWT_PREVIOUS_SECRET` from `.env.prod` and restart the API to end the compatibility window:

```bash
./start-prod.sh down
./start-prod.sh up -d
```

### Reset MFA for one user

Use this only when a user's stored MFA secret no longer matches the authenticator app. The script clears `mfa_secret` and sets `mfa_enabled=false`; the next login must enroll a new authenticator secret.

Run from the deployed repo on the production VM:

```bash
chmod +x infra/reset-user-mfa.sh
./infra/reset-user-mfa.sh user@example.com
```

For non-interactive execution:

```bash
./infra/reset-user-mfa.sh user@example.com --yes
```

After reset:

1. User logs in with email/password.
2. API returns `mfaSetupRequired=true`.
3. Mobile app calls `/auth/mfa/setup` and shows QR/manual secret.
4. User scans the new secret and verifies the 6-digit code.

### Important: special characters in .env.prod

If any value contains `=` (common in base64 secrets or URLs), the line parser in `start-prod.sh` splits only on the **first** `=` to preserve the full value. Do not quote values in `.env.prod`.

Example of safe format:
```
JWT_SECRET=abc123xyz==verylongvalue
MONGODB_URI=mongodb+srv://user:pass@host/db?retryWrites=true&w=majority
```

---

## DNS Management

Domain registrar: **Dynu** (dynu.com)

Current A records pointing to the GCP VM:

| Hostname | Type | Value |
|---|---|---|
| `tenis-uat.casacam.net` | A | 34.57.81.166 |
| `api-vaulted.casacam.net` | A | 34.57.81.166 |

To add a new subdomain: log in to Dynu → DNS Records → Add A record.

DNS propagation usually takes 1-5 minutes with Dynu.

---

## First Deploy (Reference — Already Done)

These steps document what was done to set up the VM from scratch.

```bash
# 1. SSH into VM
gcloud compute ssh tennis-backend --zone us-central1-c --project tennis-management-fcd54

# 2. Clone the repository
git clone https://github.com/frpatino6/vaulted ~/vaulted/vaulted
cd ~/vaulted/vaulted

# 3. Add 2GB swap (required — e2-micro has only 1GB RAM, Docker builds need more)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make swap permanent across reboots
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 4. Upload .env.prod from local machine (run this locally, not on the VM)
# Exit SSH first, then:
./infra/upload-env.sh

# 5. SSH back in and build the image (first build takes ~10 min due to swap usage)
cd ~/vaulted/vaulted
./start-prod.sh build

# 6. Start the API container
./start-prod.sh up -d

# 7. Update Caddy config on the VM
# Copy infra/Caddyfile from the repo to ~/Caddyfile on the VM
# Then reload Caddy:
docker exec frpatino6-caddy-1 caddy reload --config /etc/caddy/Caddyfile
```

---

## Regular Deploy (API Update)

Run these commands on the VM after pushing changes to main:

```bash
# SSH into the VM
gcloud compute ssh tennis-backend --zone us-central1-c --project tennis-management-fcd54

cd ~/vaulted/vaulted

# Pull latest code
git pull

# Rebuild and restart
./start-prod.sh down
docker compose -f docker-compose.prod.yml build --no-cache
./start-prod.sh up -d

# Verify the container is running
docker ps | grep vaulted_api

# Check logs
docker logs vaulted_api --tail 50
```

---

## Web App Deploy (Flutter)

Run this on your **local machine** (not the VM):

```bash
./infra/build-web.sh
```

This script:
1. Runs `flutter build web` with `API_BASE_URL=https://api-vaulted.casacam.net/api/`
2. Deploys the build output to Firebase Hosting project `vaulted-prod-2026`
3. Web app becomes live at `https://vaulted-prod-2026.web.app`

Requirements: `firebase-tools` installed and authenticated (`firebase login`).

---

## Caddy Configuration

Caddy handles SSL (Let's Encrypt) and reverse proxying for both apps on the VM.

The Caddyfile lives at `~/Caddyfile` on the VM and is mounted into the Caddy container.

Current routes:
- `tenis-uat.casacam.net` → tennis-backend container
- `api-vaulted.casacam.net` → vaulted_api container (port 3000)

After editing `infra/Caddyfile` in the repo, copy it to the VM and reload:

```bash
# Copy to VM
gcloud compute scp infra/Caddyfile tennis-backend:~/Caddyfile \
  --zone us-central1-c --project tennis-management-fcd54

# SSH in and reload Caddy
gcloud compute ssh tennis-backend --zone us-central1-c --project tennis-management-fcd54
docker exec frpatino6-caddy-1 caddy reload --config /etc/caddy/Caddyfile
```

---

## Cost Breakdown

All infrastructure for the current testing phase runs on free tiers.

| Service | Tier | Cost/month |
|---|---|---|
| GCP VM (e2-micro) | Free tier (us-central1) | $0 |
| GCP Persistent Disk | Free tier (30GB HDD) | $0 |
| MongoDB Atlas | M0 free cluster | $0 |
| Neon.tech PostgreSQL | Free tier | $0 |
| Upstash Redis | Free tier (10k commands/day) | $0 |
| Firebase Hosting | Free tier (10GB/month) | $0 |
| Dynu DNS | Free | $0 |
| Caddy (SSL) | Open source + Let's Encrypt | $0 |
| **Total** | | **$0** |

Note: The VM is shared with the tennis-backend app. When Vaulted moves to a paid GCP VM matching the spec in CLAUDE.md (e2-standard-4), estimated cost is ~$125-130/month.

---

## Troubleshooting

### Docker build fails with out-of-memory error

**Symptom**: `docker compose build` crashes or the VM becomes unresponsive mid-build.

**Cause**: e2-micro has only 1GB RAM. TypeScript compilation + NestJS build requires more.

**Fix**: Ensure swap is active.
```bash
free -h          # check if swap shows 2G
swapon --show    # list active swap

# If swap is missing, recreate it:
sudo swapon /swapfile
```

---

### Container starts but API returns 500 or cannot connect to database

**Symptom**: `/health` returns errors for MongoDB, PostgreSQL, or Redis.

**Cause**: Usually a malformed value in `.env.prod`.

**Fix**:
```bash
docker logs vaulted_api --tail 100
```
Look for connection errors. Common issues:
- `MONGODB_URI` missing `?retryWrites=true` or has unescaped `@` in password
- `DATABASE_URL` missing `?sslmode=require`
- `REDIS_URL` using `redis://` instead of `rediss://` (Upstash requires TLS)

Re-upload `.env.prod` if you edited it locally:
```bash
# Run locally:
./infra/upload-env.sh
# Then on VM:
./start-prod.sh down && ./start-prod.sh up -d
```

---

### Port conflict with tennis-backend Caddy

**Symptom**: Caddy fails to start or vaulted_api is not reachable after a Caddy restart.

**Cause**: The `frpatino6-caddy-1` container must be on the same Docker network as both `vaulted_api` and `tennis-backend`. If networks diverge, Caddy cannot proxy to the API.

**Fix**: Confirm `vaulted_api` is on the `frpatino6_default` network (defined in `docker-compose.prod.yml`):
```bash
docker network inspect frpatino6_default | grep vaulted
```
If missing, check that `docker-compose.prod.yml` declares:
```yaml
networks:
  default:
    external: true
    name: frpatino6_default
```

---

### .env.prod values with special characters are truncated

**Symptom**: JWT or encryption secrets appear short in the app, or Mongo URI loses everything after `=`.

**Cause**: Naive `export $(cat .env.prod)` splits on every `=`, breaking base64 values and URLs.

**Fix**: `start-prod.sh` already handles this by parsing line by line and splitting only on the first `=`. Verify you are using `./start-prod.sh up -d` and not calling `docker compose` directly.

---

### SSL certificate not issued for api-vaulted.casacam.net

**Symptom**: Browser shows "Not Secure" or ERR_SSL.

**Cause**: Either DNS has not propagated yet, or Caddy cannot reach Let's Encrypt (port 80 blocked).

**Fix**:
1. Confirm DNS: `dig api-vaulted.casacam.net` should return `34.57.81.166`
2. Check Caddy logs: `docker logs frpatino6-caddy-1 --tail 50`
3. Confirm port 80 is open on the GCP firewall (required for ACME HTTP challenge)

---

### git pull fails on VM due to local changes

**Symptom**: `git pull` reports conflicts or refuses to pull.

**Fix**:
```bash
git stash
git pull
# Only run git stash pop if the stashed changes were intentional
```
Never commit `.env.prod` or any generated file to the repo from the VM.
