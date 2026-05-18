-- Migration: add orchestrator notification preference columns
-- Run once on the production PostgreSQL database.
--
-- Usage (from the VM):
--   psql "$DATABASE_URL" -f apps/api/src/migrations/add-orchestrator-notification-preferences.sql

ALTER TABLE notification_preferences
  ADD COLUMN IF NOT EXISTS orchestrator_assigned BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS orchestrator_completed BOOLEAN NOT NULL DEFAULT TRUE;
