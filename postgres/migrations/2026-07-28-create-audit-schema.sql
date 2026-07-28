BEGIN;

CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE IF NOT EXISTS audit.change_log (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    occurred_at timestamptz NOT NULL DEFAULT now(),
    actor text,
    action text NOT NULL,
    entity_type text NOT NULL,
    entity_id text,
    payload jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS ix_change_log_occurred_at
    ON audit.change_log (occurred_at DESC);

GRANT USAGE ON SCHEMA audit TO :"runtime_user";
GRANT INSERT ON audit.change_log TO :"runtime_user";

COMMIT;