#!/usr/bin/env bash
set -euo pipefail

runtime_user="${POSTGRES_RUNTIME_USER:-}"
runtime_password="${POSTGRES_RUNTIME_PASSWORD:-}"

if [[ -z "$runtime_user$runtime_password" ]]; then
    echo "Nenhuma role de runtime configurada; ignorando 20-roles.sh"
elif [[ -z "$runtime_user" || -z "$runtime_password" ]]; then
    echo "POSTGRES_RUNTIME_USER e POSTGRES_RUNTIME_PASSWORD devem ser informados juntos." >&2
    exit 1
else
    psql \
        --set=ON_ERROR_STOP=1 \
        --username "$POSTGRES_USER" \
        --dbname "$POSTGRES_DB" \
        --set=runtime_user="$runtime_user" \
        --set=runtime_password="$runtime_password" <<'SQL'
SELECT format(
    'CREATE ROLE %I LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT PASSWORD %L',
    :'runtime_user',
    :'runtime_password'
)
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_roles
    WHERE rolname = :'runtime_user'
)\gexec
SQL
fi