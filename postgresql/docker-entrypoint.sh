#!/usr/bin/env bash
###############################################################################
# docker-entrypoint.sh
#
# Descrição:
#   Script principal de entrada (ENTRYPOINT) do container PostgreSQL.
#   Responsável por inicializar o cluster de dados do PostgreSQL caso ainda
#   não exista, configurar autenticação remota (scram-sha-256), definir a
#   senha do superusuário (postgres) e iniciar o servidor PostgreSQL.
#   Ao final, invoca o script docker-entrypoint-initdb.sh em background
#   para criação de database, usuário e execução de scripts customizados.
#
# Dependências:
#   - PostgreSQL 17 (imagem base: postgres:17-bookworm)
#   - gosu (já incluído na imagem oficial do PostgreSQL)
#   - docker-entrypoint-initdb.sh (copiado para /usr/local/bin/)
#
# Variáveis de Ambiente:
#   PGDATA              - Diretório de dados do PostgreSQL
#                         (padrão: /var/lib/postgresql/data)
#   POSTGRES_PASSWORD   - Senha do superusuário 'postgres' (obrigatório)
#   PG_DATABASE_ENCODING - Encoding do cluster (padrão: UTF8)
#
# Uso:
#   Este script é executado automaticamente como ENTRYPOINT do container.
#   Não deve ser invocado manualmente. Configure as variáveis de ambiente
#   no docker-compose.yml ou no 'docker run -e'.
#
#   Exemplo:
#     docker run -e POSTGRES_PASSWORD=MinhaSenh@123 lzocateli/postgresql:17
#
###############################################################################
set -e

PGDATA="${PGDATA:-/var/lib/postgresql/data}"

echo "$0: Starting PostgreSQL"

# Fix permissions
chown postgres:postgres "$PGDATA"
chmod 700 "$PGDATA"
chown postgres:postgres /var/run/postgresql

# Initialize database cluster if not exists
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "$0: Initializing PostgreSQL data directory"

    gosu postgres initdb \
        --encoding="${PG_DATABASE_ENCODING:-UTF8}" \
        --locale=en_US.UTF-8 \
        -D "$PGDATA"

    # Allow remote connections with password authentication
    echo "host all all 0.0.0.0/0 scram-sha-256" >> "$PGDATA/pg_hba.conf"
    echo "host all all ::/0 scram-sha-256" >> "$PGDATA/pg_hba.conf"

    # Listen on all interfaces
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PGDATA/postgresql.conf"

    # Start temporarily to set superuser password
    gosu postgres pg_ctl -D "$PGDATA" -w start

    if [ "$POSTGRES_PASSWORD" ]; then
        psql -U postgres -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_PASSWORD}';"
    fi

    gosu postgres pg_ctl -D "$PGDATA" -w stop
fi

docker-entrypoint-initdb.sh & exec gosu postgres postgres -D "$PGDATA"
