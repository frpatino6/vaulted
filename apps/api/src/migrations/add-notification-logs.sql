-- Migration: create notification_logs table
-- Run once on the production PostgreSQL database (Neon.tech).
--
-- Usage (from the VM):
--   psql "$DATABASE_URL" -f apps/api/src/migrations/add-notification-logs.sql

CREATE TABLE IF NOT EXISTS notification_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   VARCHAR NOT NULL,
  user_id     VARCHAR NOT NULL,
  type        VARCHAR(50) NOT NULL,
  title       VARCHAR NOT NULL,
  body        TEXT NOT NULL,
  data        JSONB DEFAULT NULL,
  read_at     TIMESTAMPTZ DEFAULT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notification_logs_tenant_id ON notification_logs (tenant_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_id   ON notification_logs (user_id);
