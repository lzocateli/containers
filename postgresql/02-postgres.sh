#!/bin/bash
#===============================================================================
# Script: 02-postgres.sh
# Descrição: Inicia PostgreSQL 18 com pgvector para o blog (Comentario + Listmonk)
# Autor: Lincoln Zocateli
#
# Dependências:
#   - Podman (rootless mode)
#   - Arquivo: /userapps/blog/.env.production
#   - Diretório de dados, scripts e backups configurados no .env.production
#   - Scripts de inicialização: /userapps/blog/postgres_scripts/init-db.sql  (template)
#   - Rede: lzo (criar com 01-network.sh)
#
# Uso: ./02-postgres.sh
#
# Exemplos:
#   ./02-postgres.sh
#   podman logs -f postgres  # Ver logs
#===============================================================================

# Modo rigoroso para execução em pipelines
set -euo pipefail

CONTAINER_NAME="postgres"
IMAGE="lzocateli/postgresql:18.4-pgvector0.8.5-bookworm"
NETWORK="lzo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_DIR="$SCRIPT_DIR/init"

echo "🗄️  Iniciando PostgreSQL: $CONTAINER_NAME"

# Carrega e exporta variáveis de ambiente do .env.production
if [ ! -f "$DEPLOY_DIR/.env.production" ]; then
    echo "❌ Erro: Arquivo $DEPLOY_DIR/.env.production não encontrado"
    exit 1
fi

set -a
source "$DEPLOY_DIR/.env.production"
set +a

for required_variable in POSTGRES_PASSWORD POSTGRES_DATA POSTGRES_BACKUP_DIR; do
    if [ -z "${!required_variable:-}" ]; then
        echo "❌ Erro: Variável $required_variable não definida em .env.production"
        exit 1
    fi
done

PG_DATA_DIR="$POSTGRES_DATA"
PG_BACKUP_DIR="$POSTGRES_BACKUP_DIR"
POSTGRES_USER="${POSTGRES_USER:-blogadmin}"
POSTGRES_DB="${POSTGRES_DB:-blogdb}"
POSTGRES_SHM_SIZE="${POSTGRES_SHM_SIZE:-256m}"
optional_init_environment=()

for optional_variable in POSTGRES_RUNTIME_USER POSTGRES_RUNTIME_PASSWORD POSTGRES_APP_SCHEMA; do
    if [ -n "${!optional_variable:-}" ]; then
        optional_init_environment+=(--env "$optional_variable=${!optional_variable}")
    fi
done

# Cria diretórios se não existirem
if [ ! -d "$PG_DATA_DIR" ]; then
    echo "📁 Criando diretório de dados: $PG_DATA_DIR"
    mkdir -p "$PG_DATA_DIR"
    echo "🔐 Ajustando permissões rootless (primeira inicialização)..."
    podman unshare chown -R 999:999 "$PG_DATA_DIR"
    echo "✅ Permissões ajustadas"
fi

if [ ! -d "$INIT_DIR" ]; then
    echo "❌ Erro: Diretório de bootstrap $INIT_DIR não encontrado"
    exit 1
fi

mkdir -p "$PG_BACKUP_DIR"

# Verifica se o container já está rodando
if podman ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "⚠️  Container $CONTAINER_NAME já está rodando"
    echo "   Use 'podman stop $CONTAINER_NAME' para parar primeiro"
    exit 0
fi

# Remove container antigo se existir (stopped)
if podman ps -a --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "🧹 Removendo container antigo..."
    podman rm "$CONTAINER_NAME"
fi

# Executa o container
echo "🚀 Executando container..."
podman run -d \
    --name "$CONTAINER_NAME" \
    --network "$NETWORK" \
    --restart=always \
    --shm-size "$POSTGRES_SHM_SIZE" \
    -e POSTGRES_USER="$POSTGRES_USER" \
    -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    -e POSTGRES_DB="$POSTGRES_DB" \
    -e TZ=America/Sao_Paulo \
    "${optional_init_environment[@]}" \
    -v "$PG_DATA_DIR":/var/lib/postgresql:Z \
    -v "$INIT_DIR/00-extensions.sql":/docker-entrypoint-initdb.d/00-extensions.sql:Z,ro \
    -v "$INIT_DIR/10-schemas.sql":/docker-entrypoint-initdb.d/10-schemas.sql:Z,ro \
    -v "$INIT_DIR/20-roles.sh":/docker-entrypoint-initdb.d/20-roles.sh:Z,ro \
    -v "$INIT_DIR/30-permissions.sql":/docker-entrypoint-initdb.d/30-permissions.sql:Z,ro \
    -v "$INIT_DIR/40-application.sql":/docker-entrypoint-initdb.d/40-application.sql:Z,ro \
    -v "$PG_BACKUP_DIR":/backups:Z \
    --health-cmd "postgresql-healthcheck" \
    --health-interval 10s \
    --health-timeout 5s \
    --health-retries 5 \
    --health-start-period 30s \
    "$IMAGE"

# Aguarda o bootstrap síncrono do entrypoint oficial e o health check do banco.
for attempt in {1..60}; do
    health_status="$(podman inspect --format '{{.State.Health.Status}}' "$CONTAINER_NAME")"
    if [ "$health_status" = "healthy" ]; then
        break
    fi

    if [ "$health_status" = "unhealthy" ]; then
        echo "❌ PostgreSQL ficou indisponível durante a inicialização"
        podman logs "$CONTAINER_NAME"
        exit 1
    fi

    sleep 2
done

if [ "${health_status:-}" != "healthy" ]; then
    echo "❌ PostgreSQL não ficou saudável dentro do tempo esperado"
    podman logs "$CONTAINER_NAME"
    exit 1
fi

# Mantém as extensões de plataforma disponíveis mesmo quando o diretório de
# scripts externo não contém o bootstrap padrão da imagem.
podman exec \
    --env PGPASSWORD="$POSTGRES_PASSWORD" \
    "$CONTAINER_NAME" \
    psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<'SQL'
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;
SQL

echo "✅ PostgreSQL iniciado com sucesso!"
echo ""
echo "📊 Status do container:"
podman ps --filter "name=$CONTAINER_NAME"
echo ""
echo "💡 Dicas:"
echo "   • Ver logs: podman logs -f $CONTAINER_NAME"
echo "   • Dados em: $PG_DATA_DIR"
echo "   • Scripts em: $INIT_DIR"
echo "   • Backups em: $PG_BACKUP_DIR"
