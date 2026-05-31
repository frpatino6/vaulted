# Vaulted — Plan Ampliado de Revisiones de Seguridad

## Contexto
Target: Ultra-high-net-worth families. Breach cost = reputational destruction + legal liability.
Compliance targets: SOC 2 Type II · CCPA · ISO 27001

---

## CATEGORÍAS NUEVAS (más allá del pentest inicial)

---

### REV-01 — Dependency & Supply Chain Security
**Riesgo**: Un paquete npm malicioso o con CVE puede comprometer el servidor completo.

```bash
# 1. Audit directo
cd apps/api && npm audit --audit-level=high

# 2. Dependencias desactualizadas con CVEs conocidos
npx npm-check-updates --doctor

# 3. Detección de typosquatting y paquetes maliciosos
npx lockfile-lint --path package-lock.json --type npm \
  --allowed-hosts npm --validate-https

# 4. SBOM (Software Bill of Materials) — requerido para SOC 2
npx @cyclonedx/cyclonedx-npm --output-format JSON > sbom.json

# 5. Verificar integridad de lockfile (no fue modificado manualmente)
npm ci --dry-run
```

**Automatizar en CI**: `npm audit` debe correr en cada PR y bloquear si hay HIGH o CRITICAL.

---

### REV-02 — Container & Image Security (Trivy)
**Riesgo**: La imagen Docker puede tener vulnerabilidades del OS base (Debian/Alpine).

```bash
# Instalar Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh

# Scan de imagen de producción
trivy image vaulted-api:latest --severity HIGH,CRITICAL

# Scan del Dockerfile (configuración)
trivy config apps/api/Dockerfile.prod

# Scan del docker-compose completo
trivy config docker-compose-fullstack.prod.yml

# Verificar que containers no corren como root
docker inspect vaulted_api | jq '.[0].Config.User'
docker inspect vaulted_mongodb | jq '.[0].Config.User'
docker inspect vaulted_postgres | jq '.[0].Config.User'

# Docker Bench Security (CIS Docker Benchmark)
docker run --rm -it \
  --net host --pid host --userns host --cap-add audit_control \
  -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
  -v /etc:/etc:ro \
  -v /lib/systemd/system:/lib/systemd/system:ro \
  -v /usr/bin/containerd:/usr/bin/containerd:ro \
  -v /usr/bin/runc:/usr/bin/runc:ro \
  -v /usr/lib/systemd:/usr/lib/systemd:ro \
  -v /var/lib:/var/lib:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --label docker_bench_security \
  docker/docker-bench-security
```

**Criterio de aprobación**: Zero CRITICAL CVEs en imagen de producción.

---

### REV-03 — SAST (Static Application Security Testing)
**Riesgo**: Vulnerabilidades en el código fuente que el pentest dinámico no alcanza.

```bash
# Semgrep — reglas específicas para Node.js/NestJS
docker run --rm -v "${PWD}:/src" semgrep/semgrep \
  semgrep --config=p/nodejs \
  --config=p/typescript \
  --config=p/jwt \
  --config=p/owasp-top-ten \
  apps/api/src/ \
  --json > semgrep-results.json

# Ver solo HIGH y CRITICAL
cat semgrep-results.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
highs = [r for r in data['results'] if r.get('extra',{}).get('severity') in ['ERROR','WARNING']]
print(f'HIGH/CRITICAL findings: {len(highs)}')
for r in highs:
    print(f'  {r[\"path\"]}:{r[\"start\"][\"line\"]} — {r[\"check_id\"]}')
"

# ESLint security plugin
cd apps/api
npx eslint --plugin security --rulesdir . src/ --ext .ts
```

---

### REV-04 — Secret Scanning (Git History)
**Riesgo**: Un secreto commiteado hace 6 meses sigue en el historial aunque se borre hoy.

```bash
# TruffleHog — escanea TODO el historial git
docker run --rm -it \
  -v "$(pwd):/repo" \
  trufflesecurity/trufflehog:latest \
  git file:///repo --only-verified

# GitLeaks — más rápido para CI
docker run -v "$(pwd):/path" zricethezav/gitleaks:latest \
  detect --source /path --verbose

# Si encuentra algo: el secreto está comprometido y DEBE rotarse aunque
# sea de hace 2 años. git filter-branch no basta.
```

**Acción si se encuentra algo**: Rotar el secreto INMEDIATAMENTE, luego hacer rewrite del historial.

---

### REV-05 — Business Logic Testing
**Riesgo**: Flujos de negocio que lógicamente no deberían ser posibles pero el código permite.

Tests manuales a verificar:

```
BL-01: Loan loop
  → Prestar ítem A a persona X
  → Desde persona X, prestar el mismo ítem A a persona Y
  → El ítem no puede estar en dos loans simultáneos
  Esperado: error en segundo loan

BL-02: Insurance overage
  → Crear policy con coverage $100,000
  → Asignar ítems con coveredValue total $500,000
  → El sistema debe alertar sobre sobre-aseguramiento
  Verificar: ¿puede un usuario asignar valor mayor al coverage sin warning?

BL-03: Deleted property items
  → Crear property → asignar ítems → eliminar property
  → Los ítems huérfanos deben ser marcados o reasignados
  Verificar: ¿GET /inventory aún retorna ítems de property eliminada?

BL-04: Expired guest backdoor
  → Crear guest con expiresAt=ayer
  → Refresh token sigue siendo válido por 7 días
  → ¿Puede el guest hacer refresh y seguir operando?
  Esperado: GuestExpirationGuard bloquea aunque el JWT sea válido

BL-05: Role downgrade
  → Owner invita a Manager
  → Manager intenta cambiarse su propio rol a Owner via PATCH /users/:id
  Esperado: 403

BL-06: Concurrent movement
  → Iniciar movement de ítem A (status: draft)
  → Desde otra sesión, eliminar ítem A
  → Completar el movement
  Verificar: ¿el movement completa sobre un ítem eliminado?

BL-07: AI rate limit bypass
  → Enviar 21 requests a /ai/chat en 60 segundos
  → El request 21 debe retornar 429
  → Intentar bypass con diferentes IPs (throttle es por tenantId, no IP)
```

---

### REV-06 — Mobile App Security (Flutter)
**Riesgo**: El cliente instala la app en un iPhone; si el tráfico puede ser interceptado, todas sus joyas están expuestas.

```bash
# 1. Certificate Pinning — verificar que Dio rechaza certs no válidos
#    Instalar Burp Suite como proxy → la app NO debe conectar

# 2. Jailbreak/Root detection — verificar en dispositivo rooteado
#    La app debe detectar y negarse a mostrar datos

# 3. Screenshot protection — en pantallas de inventario
#    FLAG_SECURE debe estar activo en Android
#    UIScreen.isCaptured debe detectarse en iOS

# 4. Datos en storage local — flutter_secure_storage
adb shell run-as com.vaulted.app find /data/data/com.vaulted.app/

# 5. Binario compilado — no debe contener secretos hardcodeados
strings apps/mobile/build/app/outputs/apk/release/app-release.apk | \
  grep -i "secret\|password\|api_key\|token" | grep -v "keystore"

# 6. Reverse engineering protection
#    APK debe estar ofuscado (flutter build --obfuscate --split-debug-info)
```

---

### REV-07 — Infrastructure Hardening (VM)
**Riesgo**: La VM es el único punto de falla. Si es comprometida, todo cae.

```bash
# Desde la VM: ejecutar como root o sudo

# 1. CIS Benchmark Level 1 para Ubuntu
docker run --rm -v /:/host:ro \
  --pid=host --net=host \
  aquasecurity/kube-bench:latest node 2>/dev/null || \
  # Para VM standalone:
  apt-get install -y lynis && lynis audit system

# 2. UFW — solo puertos necesarios
ufw status verbose
# Esperado: only 80, 443, <SSH_PORT> IN

# 3. Fail2ban activo
fail2ban-client status
fail2ban-client status sshd

# 4. SSH hardening
sshd -T | grep -E "permitempty|passwordauth|rootlogin|pubkeyauth|x11|allowagent"
# Esperado: PasswordAuthentication no, PermitRootLogin no

# 5. Kernel security parameters
sysctl net.ipv4.conf.all.rp_filter        # debe ser 1
sysctl net.ipv4.conf.all.accept_redirects # debe ser 0
sysctl net.ipv4.tcp_syncookies            # debe ser 1
sysctl kernel.randomize_va_space          # debe ser 2 (ASLR)

# 6. Verificar no hay servicios innecesarios
ss -tlnp | grep -v "docker\|caddy\|sshd"

# 7. Verificar logs de acceso SSH (últimas 50 líneas)
journalctl -u ssh --since "7 days ago" | grep -i "failed\|invalid"
```

---

### REV-08 — Monitoring & Alerting (SIEM lite)
**Riesgo**: Sin alertas, un ataque puede durar días antes de ser detectado.

Eventos críticos que DEBEN generar alerta inmediata (Sentry + email):

| Evento | Fuente | Acción |
|--------|--------|--------|
| 5+ login fallidos en 60s (mismo user) | AuditLog | Email al owner del tenant |
| Login exitoso desde IP nueva (geolocation) | AuditLog | Push notification al owner |
| Token de invitación usado desde IP distinta al que se creó | AuditLog | Email |
| Acceso a datos de seguro (cualquier GET insurance) fuera de horario normal | AuditLog | Log + alerta |
| 3+ errores 5xx en 60s | API logs | PagerDuty/email DevOps |
| Container caído (healthcheck fail) | Docker | Email DevOps |
| Disco > 80% lleno | VM cron | Email DevOps |
| Backup falla | Backup container | Email DevOps |
| Certificado SSL expira en < 14 días | Caddy/cron | Email DevOps |

Implementar con: Sentry (ya configurado) + webhook a Slack/email via Resend.

---

### REV-09 — Penetration Testing Externo (Trimestral)
**Riesgo**: Óptica del cliente — quiere ver que una empresa externa independiente validó la seguridad.

Firmas recomendadas para MVP stage:
- **Bishop Fox** (USA, especialistas en SaaS/fintech)
- **Cobalt** (plataforma de pentest as a service, ~$3,000-5,000 por engagement)
- **Synack** (bug bounty privado + pentest)
- **HackerOne** (programa privado de bug bounty)

Alcance mínimo del primer engagement:
- API REST (authentication, authorization, injection)
- WebSocket
- Mobile app (iOS binary)
- Infrastructure (VM, Docker, network)

Entregable esperado: Informe con CVSS scores, evidencia de exploits, remediation guidance.

---

### REV-10 — Disaster Recovery & Business Continuity
**Riesgo**: El primer cliente HNWI preguntará "¿qué pasa si el servidor cae?"

Pruebas trimestrales:

```bash
# 1. Restore test — verificar que el backup es restaurable
# Desde backup más reciente:
LATEST=$(ls -t /backups | head -1)

# Restore MongoDB
openssl enc -d -aes-256-cbc -pbkdf2 -k "$BACKUP_ENCRYPTION_KEY" \
  -in "/backups/$LATEST/mongodb.archive.enc" | \
  mongorestore --archive --gzip --host localhost:27018  # puerto de test

# Restore PostgreSQL
openssl enc -d -aes-256-cbc -pbkdf2 -k "$BACKUP_ENCRYPTION_KEY" \
  -in "/backups/$LATEST/postgres.dump.enc" \
  -out /tmp/restore.dump
pg_restore -h localhost -p 5433 -U vaulted -d vaulted_test /tmp/restore.dump

# 2. RTO (Recovery Time Objective) — medir cuánto tarda en levantar todo
time (./start-prod-full.sh down && ./start-prod-full.sh up -d)
# Objetivo: < 5 minutos

# 3. Snapshot GCP — verificar que los snapshots diarios existen
gcloud compute disks list --filter="name:tennis-backend"
gcloud compute snapshots list --sort-by=creationTimestamp | tail -5
```

---

## Roadmap de implementación

| Sprint | Revisiones | Prioridad |
|--------|-----------|-----------|
| Inmediato | REV-04 (secret scan), REV-01 (npm audit) | 🔴 Antes del primer cliente |
| Sprint 1 | REV-03 (SAST), REV-02 (Trivy), REV-07 (VM hardening) | 🟠 Alta |
| Sprint 2 | REV-05 (business logic), REV-08 (monitoring) | 🟡 Media |
| Sprint 3 | REV-06 (mobile), REV-10 (DR test) | 🟡 Media |
| Trimestral | REV-09 (pentest externo) | 🔵 Continuo |

---

## VM Sizing para fullstack Docker

| Configuración | vCPU | RAM | Costo/mes | Recomendado para |
|--------------|------|-----|-----------|-----------------|
| **e2-micro** (actual) | 1 | 0.6 GB | $0 free | API only (actual) |
| **e2-small** | 2 | 2 GB | ~$13 | ❌ No suficiente |
| **e2-medium** | 2 | 4 GB | ~$26 | Staging/dev |
| **e2-standard-2** | 2 | 8 GB | ~$49 | ✅ Mínimo producción (1-3 tenants) |
| **e2-standard-4** | 4 | 16 GB | ~$125 | ✅ Producción recomendada |
| **e2-standard-8** | 8 | 32 GB | ~$250 | Escala 10+ tenants |

**Recomendación para el primer cliente**: e2-standard-2 ($49/mo). Upgrade a e2-standard-4 al tener 3+ tenants activos.

**Migración de e2-micro a e2-standard-2** (sin downtime):
1. GCP Console → VM → Edit → Machine type → e2-standard-2
2. Requiere stop/start de VM (~2 min de downtime)
3. Caddy y todos los containers levantan automáticamente (restart: always)
