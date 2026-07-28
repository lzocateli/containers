#!/usr/bin/env bash
set -euo pipefail

database_user="${POSTGRES_USER:-postgres}"
database_name="${POSTGRES_DB:-$database_user}"

pg_isready --quiet --username "$database_user" --dbname "$database_name"

# Durante o bootstrap, o entrypoint oficial sobe um servidor temporário com
# listen_addresses vazio. O processo definitivo recebe uma configuração de rede.
listen_addresses="$(psql \
    --no-psqlrc \
    --tuples-only \
    --no-align \
    --quiet \
    --username "$database_user" \
    --dbname "$database_name" \
    --command 'SHOW listen_addresses;')"

test -n "$listen_addresses"