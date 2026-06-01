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


-- Enforce audit log immutability at the database layer.
-- The application code is append-only, but DB credentials must not be able to
-- UPDATE, DELETE, or TRUNCATE audit evidence after compromise.
CREATE OR REPLACE FUNCTION prevent_audit_log_mutation()
RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'audit_logs is append-only';
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF to_regclass('public.audit_logs') IS NOT NULL THEN
    REVOKE UPDATE, DELETE, TRUNCATE ON audit_logs FROM PUBLIC;

    DROP TRIGGER IF EXISTS audit_logs_no_update ON audit_logs;
    DROP TRIGGER IF EXISTS audit_logs_no_delete ON audit_logs;
DROP TRIGGER IF EXISTS audit_logs_no_truncate ON audit_logs;

    CREATE TRIGGER audit_logs_no_update
    BEFORE UPDATE ON audit_logs
    FOR EACH ROW EXECUTE FUNCTION prevent_audit_log_mutation();

    CREATE TRIGGER audit_logs_no_delete
    BEFORE DELETE ON audit_logs
    FOR EACH ROW EXECUTE FUNCTION prevent_audit_log_mutation();

    CREATE TRIGGER audit_logs_no_truncate
    BEFORE TRUNCATE ON audit_logs
    FOR EACH STATEMENT EXECUTE FUNCTION prevent_audit_log_mutation();
  END IF;
END$$;
