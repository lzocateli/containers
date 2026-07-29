#!/usr/bin/env bash
set -Eeuo pipefail

readonly SQLCMD=/opt/mssql-tools18/bin/sqlcmd
readonly INIT_DIRECTORY=/docker-entrypoint-initdb.d
readonly INIT_LOCK=/var/opt/mssql/.container-init-complete

show_help() {
  cat <<'EOF'
Inicializa uma instancia SQL Server 2025 uma unica vez.

Uso:
  docker-entrypoint-initdb.sh
  docker-entrypoint-initdb.sh --help

Variaveis:
  MSSQL_SA_PASSWORD       Senha obrigatoria do login sa.
  MSSQL_DATABASE          Banco opcional a criar.
  MSSQL_DATABASE_COLLATE  Collation do banco opcional.
  MSSQL_USER              Login opcional da aplicacao.
  MSSQL_PASSWORD          Senha obrigatoria quando MSSQL_USER for informado.

Arquivos .sql e .sh em /docker-entrypoint-initdb.d sao executados em ordem
alfabetica. O marcador persistente so e criado quando todas as etapas terminam.
EOF
}

case "${1:-}" in
  -h|--help)
    show_help
    exit 0
    ;;
esac

validate_identifier() {
  local name=$1
  local value=$2

  if [[ ! $value =~ ^[A-Za-z_][A-Za-z0-9_]{0,127}$ ]]; then
    echo "$0: $name deve ser um identificador SQL simples com ate 128 caracteres" >&2
    return 1
  fi
}

run_sql() {
  SQLCMDPASSWORD="$MSSQL_SA_PASSWORD" "$SQLCMD" \
    -S localhost -U sa -C -b -V 16 "$@"
}

if [[ -f $INIT_LOCK ]]; then
  echo "$0: inicializacao ja concluida"
  exit 0
fi

: "${MSSQL_SA_PASSWORD:?MSSQL_SA_PASSWORD e obrigatoria}"

if [[ -n ${MSSQL_DATABASE:-} ]]; then
  validate_identifier MSSQL_DATABASE "$MSSQL_DATABASE"
fi

if [[ -n ${MSSQL_USER:-} ]]; then
  validate_identifier MSSQL_USER "$MSSQL_USER"
  : "${MSSQL_PASSWORD:?MSSQL_PASSWORD e obrigatoria quando MSSQL_USER e informado}"
elif [[ -n ${MSSQL_PASSWORD:-} ]]; then
  echo "$0: MSSQL_USER e obrigatoria quando MSSQL_PASSWORD e informado" >&2
  exit 1
fi

readonly database_collation=${MSSQL_DATABASE_COLLATE:-SQL_Latin1_General_CP1_CI_AI}
validate_identifier MSSQL_DATABASE_COLLATE "$database_collation"

for attempt in {1..60}; do
  if run_sql -Q "SELECT 1" -o /dev/null 2>/dev/null; then
    echo "$0: SQL Server pronto para inicializacao"
    break
  fi

  if (( attempt == 60 )); then
    echo "$0: SQL Server nao ficou pronto em 60 segundos" >&2
    exit 1
  fi

  sleep 1
done

temporary_sql=$(mktemp)
trap 'rm -f "$temporary_sql"' EXIT

if [[ -n ${MSSQL_DATABASE:-} ]]; then
  cat > "$temporary_sql" <<EOSQL
IF DB_ID(N'${MSSQL_DATABASE}') IS NULL
  CREATE DATABASE [${MSSQL_DATABASE}] COLLATE ${database_collation};
GO
ALTER DATABASE [${MSSQL_DATABASE}] SET COMPATIBILITY_LEVEL = 170;
GO
EOSQL
  run_sql -i "$temporary_sql"
fi

if [[ -n ${MSSQL_USER:-} ]]; then
  default_database=${MSSQL_DATABASE:-master}
  escaped_password=${MSSQL_PASSWORD//\'/\'\'}

  cat > "$temporary_sql" <<EOSQL
USE [master];
GO
IF SUSER_ID(N'${MSSQL_USER}') IS NULL
  CREATE LOGIN [${MSSQL_USER}]
    WITH PASSWORD = N'${escaped_password}',
       DEFAULT_DATABASE = [${default_database}],
       CHECK_POLICY = ON;
GO
EOSQL

  if [[ -n ${MSSQL_DATABASE:-} ]]; then
    cat >> "$temporary_sql" <<EOSQL
USE [${MSSQL_DATABASE}];
GO
IF DATABASE_PRINCIPAL_ID(N'${MSSQL_USER}') IS NULL
  CREATE USER [${MSSQL_USER}] FOR LOGIN [${MSSQL_USER}];
GO
IF ISNULL(IS_ROLEMEMBER(N'db_owner', N'${MSSQL_USER}'), 0) = 0
  ALTER ROLE [db_owner] ADD MEMBER [${MSSQL_USER}];
GO
EOSQL
  fi

  run_sql -i "$temporary_sql"
fi

shopt -s nullglob
init_files=("$INIT_DIRECTORY"/*)
for init_file in "${init_files[@]}"; do
  case "$init_file" in
    *.sql)
      echo "$0: executando $init_file"
      run_sql -X -i "$init_file"
      ;;
    *.sh)
      echo "$0: executando $init_file"
      bash "$init_file"
      ;;
    *)
      echo "$0: ignorando $init_file"
      ;;
  esac
done

touch "$INIT_LOCK"
echo "$0: inicializacao concluida"
