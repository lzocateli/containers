#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Valida uma imagem Playwright E2E ja construida.

Uso:
  smoke-test.sh --image REFERENCIA
  smoke-test.sh --help
EOF
}

fail() {
  printf 'erro: %s; consulte --help\n' "$1" >&2
  exit 1
}

image_ref=""
while (($# > 0)); do
  case "$1" in
    --image)
      (($# >= 2)) || fail "--image exige uma referencia"
      image_ref="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "argumento desconhecido: $1"
      ;;
  esac
done

[[ -n "$image_ref" ]] || fail "--image e obrigatorio"

if command -v docker.exe >/dev/null 2>&1; then
  docker_command=docker.exe
elif command -v docker >/dev/null 2>&1; then
  docker_command=docker
else
  fail "Docker 24+ nao foi encontrado"
fi

"$docker_command" image inspect "$image_ref" >/dev/null 2>&1 || fail "imagem local nao encontrada"

entrypoint="$("$docker_command" image inspect --format '{{json .Config.Entrypoint}}' "$image_ref")"
[[ "$entrypoint" == '["uv","run","--frozen","pytest","--confcutdir=/app"]' ]] || fail "entrypoint inesperado"

version_output="$("$docker_command" run --rm --entrypoint uv "$image_ref" run --frozen pytest --version)"
[[ "$version_output" == pytest\ 8.3.4* ]] || fail "versao pytest inesperada: $version_output"

echo "Smoke test concluido: $image_ref"