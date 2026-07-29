#!/usr/bin/env bash
set -Eeuo pipefail

show_help() {
	cat <<'EOF'
Inicia o SQL Server 2025 e executa o bootstrap em segundo plano.

Uso:
  docker-entrypoint.sh [comando]
  docker-entrypoint.sh --help

Sem um comando alternativo, inicia /opt/mssql/bin/sqlservr. O runtime deve
fornecer ACCEPT_EULA=Y e MSSQL_SA_PASSWORD. Consulte o README.md para as
variaveis opcionais e exemplos de Docker e Compose.
EOF
}

case "${1:-}" in
	-h|--help)
		show_help
		exit 0
		;;
esac

if [[ $# -gt 0 && "$1" != "/opt/mssql/bin/sqlservr" && "$1" != "sqlservr" ]]; then
	exec "$@"
fi

echo "$0: iniciando SQL Server 2025"
docker-entrypoint-initdb.sh &
exec /opt/mssql/bin/sqlservr
