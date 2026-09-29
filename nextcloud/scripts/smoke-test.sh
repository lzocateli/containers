#!/usr/bin/env bash
set -Eeuo pipefail

readonly default_image='lzocateli/nextcloud:35.0.1-r1'
readonly postgres_image='postgres:17-alpine@sha256:b0f9560a2de083e2cc7382e75f808c7381a32852a7ec49117deedb300e552b24'
readonly redis_image='redis:7-alpine@sha256:858f009f9709ce576febc734aa78b8f6d624b82571f9ddb6bda4377c833b3499'
image="$default_image"
timeout_seconds=600

show_help() {
  cat <<'EOF'
Uso: smoke-test.sh [--image IMAGEM] [--timeout SEGUNDOS] [--help]

Sobe uma stack temporaria com PostgreSQL 17, Redis 7 e a imagem Nextcloud,
verifica instalacao, cache Redis, health HTTP e persistencia apos recriar o app.
Todos os containers, a rede e o volume de teste sao removidos ao terminar.

Dependencias: Bash 4+, Docker Engine 25+ com daemon acessivel e openssl.
Variaveis de ambiente do daemon Docker sao respeitadas.

Opcoes:
  --image IMAGEM       Imagem local a testar (padrao: lzocateli/nextcloud:35.0.1-r1)
  --timeout SEGUNDOS   Limite para bootstrap/health (padrao: 600)
  -h, --help           Exibe esta ajuda sem acessar o Docker

Exemplo:
  bash nextcloud/scripts/smoke-test.sh --image lzocateli/nextcloud:35.0.1-r1

Documentacao: nextcloud/README.md
EOF
}

fail() {
  printf 'ERRO: %s\n' "$1" >&2
  exit 1
}

while (($#)); do
  case "$1" in
    --image)
      (($# >= 2)) || fail 'Informe uma imagem para --image.'
      image="$2"
      shift 2
      ;;
    --timeout)
      (($# >= 2)) || fail 'Informe segundos para --timeout.'
      [[ "$2" =~ ^[1-9][0-9]*$ ]] || fail '--timeout deve ser um inteiro positivo.'
      timeout_seconds="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      fail "Opcao desconhecida: $1. Use --help."
      ;;
  esac
done

command -v docker >/dev/null || fail 'Docker CLI nao encontrado.'
command -v openssl >/dev/null || fail 'openssl nao encontrado.'
docker info >/dev/null 2>&1 || fail 'Docker daemon inacessivel.'

suffix="${RANDOM}${RANDOM}"
network="nextcloud-smoke-${suffix}"
volume="nextcloud-smoke-${suffix}"
database="nextcloud-smoke-db-${suffix}"
redis="nextcloud-smoke-redis-${suffix}"
app="nextcloud-smoke-app-${suffix}"
password="$(openssl rand -hex 24)"
admin_password="$(openssl rand -hex 24)"
export POSTGRES_PASSWORD="$password"
export REDIS_PASSWORD="$password"
export NEXTCLOUD_ADMIN_PASSWORD="$admin_password"

cleanup() {
  docker rm --force "$app" "$database" "$redis" >/dev/null 2>&1 || true
  docker volume rm "$volume" >/dev/null 2>&1 || true
  docker network rm "$network" >/dev/null 2>&1 || true
}
trap cleanup EXIT

wait_healthy() {
  local container="$1"
  local start=$SECONDS
  local state

  while ((SECONDS - start < timeout_seconds)); do
    state="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container" 2>/dev/null || true)"
    case "$state" in
      healthy|running) return 0 ;;
      unhealthy|exited|dead) docker logs "$container" >&2; return 1 ;;
    esac
    sleep 5
  done

  docker logs "$container" >&2
  return 1
}

docker network create "$network" >/dev/null
docker volume create "$volume" >/dev/null

docker run --detach --name "$database" --network "$network" \
  --health-cmd 'pg_isready -U nextcloud -d nextcloud' \
  --health-interval 5s --health-timeout 3s --health-retries 20 \
  --env POSTGRES_DB=nextcloud --env POSTGRES_USER=nextcloud \
  --env POSTGRES_PASSWORD "$postgres_image" >/dev/null

docker run --detach --name "$redis" --network "$network" \
  --health-cmd 'redis-cli -a "$REDIS_PASSWORD" ping 2>/dev/null | grep -q PONG' \
  --health-interval 5s --health-timeout 3s --health-retries 20 \
  --env REDIS_PASSWORD "$redis_image" \
  sh -c 'umask 077; printf "requirepass %s\nappendonly yes\n" "$REDIS_PASSWORD" > /tmp/redis-smoke.conf; exec redis-server /tmp/redis-smoke.conf' >/dev/null

wait_healthy "$database" || fail 'PostgreSQL nao ficou saudavel.'
wait_healthy "$redis" || fail 'Redis nao ficou saudavel.'

docker run --detach --name "$app" --network "$network" --volume "$volume:/var/www/html" \
  --env POSTGRES_HOST="$database" --env POSTGRES_DB=nextcloud \
  --env POSTGRES_USER=nextcloud --env POSTGRES_PASSWORD \
  --env NEXTCLOUD_ADMIN_USER=smoke-admin --env NEXTCLOUD_ADMIN_PASSWORD \
  --env NEXTCLOUD_TRUSTED_DOMAINS=localhost --env REDIS_HOST="$redis" \
  --env REDIS_HOST_PASSWORD "$image" >/dev/null

wait_healthy "$app" || fail 'Nextcloud nao ficou saudavel; veja os logs acima.'
docker exec --user www-data "$app" php occ status --output=json | grep -q '"installed":true' \
  || fail 'Nextcloud nao concluiu o bootstrap com PostgreSQL.'
docker exec --user www-data "$app" php occ config:system:get memcache.locking \
  | grep -q 'OC\\Memcache\\Redis' || fail 'File locking Redis nao foi configurado.'

instance_id="$(docker exec --user www-data "$app" php occ config:system:get instanceid)"
docker rm --force "$app" >/dev/null
docker run --detach --name "$app" --network "$network" --volume "$volume:/var/www/html" \
  --env POSTGRES_HOST="$database" --env POSTGRES_DB=nextcloud \
  --env POSTGRES_USER=nextcloud --env POSTGRES_PASSWORD \
  --env NEXTCLOUD_TRUSTED_DOMAINS=localhost --env REDIS_HOST="$redis" \
  --env REDIS_HOST_PASSWORD "$image" >/dev/null
wait_healthy "$app" || fail 'Nextcloud nao voltou saudavel com o volume persistente.'
[[ "$(docker exec --user www-data "$app" php occ config:system:get instanceid)" == "$instance_id" ]] \
  || fail 'A configuracao nao persistiu apos recriar o container.'

printf 'Smoke test aprovado: bootstrap PostgreSQL, locking Redis, health e persistencia.\n'