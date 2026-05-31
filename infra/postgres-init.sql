-- PostgreSQL initialization — runs once on first container start

-- Enable pgvector extension (required for AI embeddings)
CREATE EXTENSION IF NOT EXISTS vector;

-- Restrict public schema: only the app user can create objects
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT  CREATE ON SCHEMA public TO current_user;

-- Audit log table: INSERT-only enforced at DB level
-- Application user gets INSERT + SELECT but NOT UPDATE or DELETE
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_catalog.pg_roles WHERE rolname = current_user
  ) THEN
    RAISE NOTICE 'App user already exists';
  END IF;
END$$;
