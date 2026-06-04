-- Add failed_login_attempts and locked_until columns to users table.
-- These were added to the User entity in SEC-001 (brute force protection)
-- but the production database must be migrated manually.

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS failed_login_attempts INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS locked_until TIMESTAMPTZ NULL;
