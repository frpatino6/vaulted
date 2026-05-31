#!/bin/sh
# Nightly backup: MongoDB + PostgreSQL → encrypted archives on backup volume
# Runs inside backup container. Retains BACKUP_RETAIN_DAYS days.
set -eu

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/backups/$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

echo "[backup] Starting at $TIMESTAMP"

# Install tools on first run
apk add --no-cache --quiet mongodb-tools postgresql-client openssl 2>/dev/null || true

# ── MongoDB dump ──────────────────────────────────────────────
echo "[backup] Dumping MongoDB..."
mongodump \
  --host mongodb:27017 \
  --username "$MONGO_APP_USER" \
  --password "$MONGO_APP_PASSWORD" \
  --authenticationDatabase vaulted \
  --db vaulted \
  --archive="$BACKUP_DIR/mongodb.archive" \
  --gzip
echo "[backup] MongoDB done"

# ── PostgreSQL dump ───────────────────────────────────────────
echo "[backup] Dumping PostgreSQL..."
PGPASSWORD="$POSTGRES_PASSWORD" pg_dump \
  -h postgres -U "$POSTGRES_USER" -d vaulted \
  -Fc -f "$BACKUP_DIR/postgres.dump"
echo "[backup] PostgreSQL done"

# ── Encrypt both archives ─────────────────────────────────────
echo "[backup] Encrypting..."
openssl enc -aes-256-cbc -pbkdf2 -iter 100000 \
  -k "$BACKUP_ENCRYPTION_KEY" \
  -in  "$BACKUP_DIR/mongodb.archive" \
  -out "$BACKUP_DIR/mongodb.archive.enc"

openssl enc -aes-256-cbc -pbkdf2 -iter 100000 \
  -k "$BACKUP_ENCRYPTION_KEY" \
  -in  "$BACKUP_DIR/postgres.dump" \
  -out "$BACKUP_DIR/postgres.dump.enc"

# Remove unencrypted copies
rm "$BACKUP_DIR/mongodb.archive" "$BACKUP_DIR/postgres.dump"
echo "[backup] Encrypted archives saved to $BACKUP_DIR"

# ── Prune old backups ─────────────────────────────────────────
RETAIN="${BACKUP_RETAIN_DAYS:-7}"
find /backups -maxdepth 1 -type d -mtime "+$RETAIN" | while read -r old; do
  echo "[backup] Removing old backup: $old"
  rm -rf "$old"
done

echo "[backup] Completed at $(date +%Y%m%d-%H%M%S)"

# Sleep 24h then repeat (crond not available in alpine by default)
sleep 86400
exec "$0"
