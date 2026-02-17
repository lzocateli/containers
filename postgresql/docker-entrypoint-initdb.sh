#!/usr/bin/env bash
###############################################################################
# docker-entrypoint-initdb.sh
#
# Descrição:
#   Script de inicialização do banco de dados PostgreSQL.
#   Executado em background pelo docker-entrypoint.sh na primeira vez que
#   o container é iniciado. Aguarda o PostgreSQL ficar pronto e então:
#     1. Cria o database definido em PG_DATABASE (se informado)
#     2. Aplica configurações otimizadas (timezone, timeouts, isolation)
#     3. Cria o usuário definido em PG_USER/PG_PASSWORD (se informados)
#     4. Concede ownership e permissões completas ao usuário no database
#     5. Executa scripts .sh e .sql encontrados em /docker-entrypoint-initdb.d/
#
#   Um arquivo ~/init.lock é criado após a primeira execução para evitar
#   re-inicialização em restarts do container.
#
# Dependências:
#   - PostgreSQL 17 (imagem base: postgres:17-bookworm)
#   - psql (cliente PostgreSQL, já incluído na imagem)
#   - pg_isready (utilitário de verificação, já incluído na imagem)
#
# Variáveis de Ambiente:
#   PG_DATABASE          - Nome do database a ser criado (opcional)
#   PG_DATABASE_ENCODING - Encoding do database (padrão: UTF8)
#   PG_USER              - Nome do usuário da aplicação (opcional)
#   PG_PASSWORD           - Senha do usuário da aplicação (opcional)
#
# Uso:
#   Este script é invocado automaticamente pelo docker-entrypoint.sh.
#   Não deve ser executado manualmente.
#
#   Para adicionar scripts de inicialização customizados, monte um volume
#   em /docker-entrypoint-initdb.d/ contendo arquivos .sh ou .sql:
#
#     volumes:
#       - ./meus-scripts/:/docker-entrypoint-initdb.d/
#
#   Arquivos são executados em ordem alfabética na primeira inicialização.
#
###############################################################################



if [ ! -f ~/init.lock ]; then

    # wait for database to start...
    for i in {40..0}; do
      if pg_isready -U postgres &> /dev/null; then
        echo "$0: PostgreSQL started"
        break
      fi
      echo "$0: PostgreSQL startup in progress..."
      sleep 1
    done

    echo "$0: Initializing database"

  #BEGIN DATABASE CREATION
  if [ "$PG_DATABASE" ]; then

    psql -v ON_ERROR_STOP=1 -U postgres <<-EOSQL
    SELECT 'CREATE DATABASE "${PG_DATABASE}"
      ENCODING ''${PG_DATABASE_ENCODING}''
      LC_COLLATE ''en_US.UTF-8''
      LC_CTYPE ''en_US.UTF-8''
      TEMPLATE template0'
    WHERE NOT EXISTS (
      SELECT FROM pg_database WHERE datname = '${PG_DATABASE}'
    )\gexec
EOSQL

    psql -v ON_ERROR_STOP=1 -U postgres <<-EOSQL
    ALTER DATABASE "${PG_DATABASE}" SET timezone TO 'UTC';
    ALTER DATABASE "${PG_DATABASE}" SET log_statement TO 'none';
    ALTER DATABASE "${PG_DATABASE}" SET default_statistics_target TO 100;
    ALTER DATABASE "${PG_DATABASE}" SET statement_timeout TO '60s';
    ALTER DATABASE "${PG_DATABASE}" SET lock_timeout TO '10s';
    ALTER DATABASE "${PG_DATABASE}" SET idle_in_transaction_session_timeout TO '60s';
    ALTER DATABASE "${PG_DATABASE}" SET default_transaction_isolation TO 'read committed';
EOSQL

  fi
  #END DATABASE CREATION

  #BEGIN USER CREATION
  if [ "$PG_USER" ] && [ "$PG_PASSWORD" ]; then

    DEFAULT_DB="postgres"

    if [ "$PG_DATABASE" ]; then

      DEFAULT_DB=$PG_DATABASE

    fi

    psql -v ON_ERROR_STOP=1 -U postgres <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${PG_USER}') THEN
            CREATE ROLE "${PG_USER}" WITH LOGIN PASSWORD '${PG_PASSWORD}';
        END IF;
    END
    \$\$;
EOSQL

    #BEGIN BIND USER TO DATABASE AS OWNER
    if [ "$PG_DATABASE" ]; then

      	psql -v ON_ERROR_STOP=1 -U postgres <<-EOSQL
		GRANT ALL PRIVILEGES ON DATABASE "${PG_DATABASE}" TO "${PG_USER}";
		ALTER DATABASE "${PG_DATABASE}" OWNER TO "${PG_USER}";
		EOSQL

      	psql -v ON_ERROR_STOP=1 -U postgres -d "${PG_DATABASE}" <<-EOSQL
		GRANT ALL ON SCHEMA public TO "${PG_USER}";
		ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "${PG_USER}";
		ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "${PG_USER}";
		ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO "${PG_USER}";
		EOSQL

    fi
    #END BIND USER TO DATABASE AS OWNER

  fi
  #END USER CREATION

  #BEGIN INITIALIZE POSTGRESQL WITH SCRIPTS
  for f in /docker-entrypoint-initdb.d/*; do
    case "$f" in
      *.sh)     echo "$0: running $f"; . "$f" ;;
      *.sql)    echo "$0: running $f"; psql -v ON_ERROR_STOP=1 -U postgres -d "${PG_DATABASE:-postgres}" -f "$f"; echo ;;
      *)        echo "$0: ignoring $f" ;;
    esac
    echo
  done
  #END INITIALIZE POSTGRESQL WITH SCRIPTS

  touch ~/init.lock

fi

echo "$0: PostgreSQL Database ready"
