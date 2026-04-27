#!/usr/bin/env bash
###############################################################################
# docker-entrypoint-initdb.sh
#
# Descrição:
#   Script de inicialização do banco de dados Oracle XE.
#   Executado em background pelo docker-entrypoint.sh na primeira vez que
#   o container é iniciado. Aguarda o Oracle ficar pronto e então:
#     1. Cria o tablespace definido em ORACLE_TABLESPACE (se informado)
#     2. Cria o usuário/schema definido em ORACLE_USER/ORACLE_USER_PASSWORD
#     3. Concede permissões (CREATE SESSION, TABLE, SEQUENCE, VIEW, PROCEDURE)
#     4. Executa scripts .sh e .sql encontrados em /docker-entrypoint-initdb.d/
#
#   Um arquivo ~/init.lock é criado após a primeira execução para evitar
#   re-inicialização em restarts do container.
#
# Dependências:
#   - Oracle XE 21c (imagem base: gvenzl/oracle-xe:21-slim)
#   - sqlplus (já incluído na imagem)
#
# Variáveis de Ambiente:
#   ORACLE_PASSWORD       - Senha do superusuário SYS/SYSTEM (obrigatório)
#   ORACLE_DATABASE       - Nome do PDB (padrão: XEPDB1)
#   ORACLE_TABLESPACE     - Nome do tablespace a ser criado (opcional)
#   ORACLE_TABLESPACE_SIZE - Tamanho inicial do tablespace (padrão: 100M)
#   ORACLE_USER           - Nome do usuário/schema da aplicação (opcional)
#   ORACLE_USER_PASSWORD  - Senha do usuário da aplicação (opcional)
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

ORACLE_DATABASE="${ORACLE_DATABASE:-XEPDB1}"
ORACLE_TABLESPACE_SIZE="${ORACLE_TABLESPACE_SIZE:-100M}"

# sqlplus connect string as SYSTEM on the PDB
SQLPLUS="sqlplus -s SYSTEM/${ORACLE_PASSWORD}@localhost:1521/${ORACLE_DATABASE}"


if [ ! -f ~/init.lock ]; then

    # wait for database to start...
    for i in {90..0}; do
      if echo "SELECT 1 FROM DUAL;" | ${SQLPLUS} &> /dev/null; then
        echo "$0: Oracle Database started"
        break
      fi
      echo "$0: Oracle Database startup in progress..."
      sleep 2
    done

    if [ "$i" = 0 ]; then
      echo "$0: Oracle Database did not start in time"
      exit 1
    fi

    echo "$0: Initializing database"

  #BEGIN TABLESPACE CREATION
  if [ "$ORACLE_TABLESPACE" ]; then

    echo "$0: Creating tablespace ${ORACLE_TABLESPACE}"

    ${SQLPLUS} <<-EOSQL
    DECLARE
      v_count NUMBER;
    BEGIN
      SELECT COUNT(*) INTO v_count FROM dba_tablespaces WHERE tablespace_name = UPPER('${ORACLE_TABLESPACE}');
      IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLESPACE ${ORACLE_TABLESPACE}
          DATAFILE ''/opt/oracle/oradata/${ORACLE_TABLESPACE}01.dbf''
          SIZE ${ORACLE_TABLESPACE_SIZE} AUTOEXTEND ON NEXT 50M MAXSIZE 1G';
      END IF;
    END;
    /
EOSQL

  fi
  #END TABLESPACE CREATION

  #BEGIN USER CREATION
  if [ "$ORACLE_USER" ] && [ "$ORACLE_USER_PASSWORD" ]; then

    echo "$0: Creating user ${ORACLE_USER}"

    DEFAULT_TABLESPACE="USERS"

    if [ "$ORACLE_TABLESPACE" ]; then
      DEFAULT_TABLESPACE="${ORACLE_TABLESPACE}"
    fi

    ${SQLPLUS} <<-EOSQL
    DECLARE
      v_count NUMBER;
    BEGIN
      SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = UPPER('${ORACLE_USER}');
      IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE USER ${ORACLE_USER} IDENTIFIED BY "${ORACLE_USER_PASSWORD}"
          DEFAULT TABLESPACE ${DEFAULT_TABLESPACE}
          QUOTA UNLIMITED ON ${DEFAULT_TABLESPACE}';
      END IF;
    END;
    /

    GRANT CREATE SESSION TO ${ORACLE_USER};
    GRANT CREATE TABLE TO ${ORACLE_USER};
    GRANT CREATE SEQUENCE TO ${ORACLE_USER};
    GRANT CREATE VIEW TO ${ORACLE_USER};
    GRANT CREATE PROCEDURE TO ${ORACLE_USER};
    GRANT CREATE TRIGGER TO ${ORACLE_USER};
    GRANT CREATE TYPE TO ${ORACLE_USER};
EOSQL

  fi
  #END USER CREATION

  #BEGIN INITIALIZE ORACLE WITH SCRIPTS
  for f in /docker-entrypoint-initdb.d/*; do
    case "$f" in
      *.sh)     echo "$0: running $f"; . "$f" ;;
      *.sql)    echo "$0: running $f"; echo "@@$f" | ${SQLPLUS}; echo ;;
      *)        echo "$0: ignoring $f" ;;
    esac
    echo
  done
  #END INITIALIZE ORACLE WITH SCRIPTS

  touch ~/init.lock

fi

echo "$0: Oracle Database ready"
