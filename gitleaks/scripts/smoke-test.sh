#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Valida uma imagem Gitleaks ja construida.

Dependencias:
  Bash 4.4+ e Docker 24+ com acesso ao daemon.

Uso:
  smoke-test.sh --image REFERENCIA
  smoke-test.sh --help

Parametros:
  --image REFERENCIA  Imagem local que sera validada.
  -h, --help          Exibe esta ajuda e encerra.

Exemplo:
  bash gitleaks/scripts/smoke-test.sh --image local/gitleaks:test
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
  DOCKER_COMMAND=docker.exe
elif command -v docker >/dev/null 2>&1; then
  DOCKER_COMMAND=docker
else
  fail "Docker 24+ nao foi encontrado"
fi

"$DOCKER_COMMAND" image inspect "$image_ref" >/dev/null 2>&1 || fail "imagem local nao encontrada: $image_ref"

entrypoint="$("$DOCKER_COMMAND" image inspect --format '{{json .Config.Entrypoint}}' "$image_ref")"
[[ "$entrypoint" == '["gitleaks"]' ]] || fail "entrypoint inesperado: $entrypoint"

version_output="$("$DOCKER_COMMAND" run --rm --read-only "$image_ref" version)"
[[ "$version_output" == *"v8.30.1"* ]] || fail "versao Gitleaks inesperada: $version_output"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd -- "$script_dir/.." && pwd)"
if command -v wslpath >/dev/null 2>&1; then
  docker_repository_root="$(wslpath -w "$repository_root")"
elif command -v cygpath >/dev/null 2>&1; then
  docker_repository_root="$(cygpath -w "$repository_root")"
else
  docker_repository_root="$repository_root"
fi

"$DOCKER_COMMAND" run --rm --read-only \
  --volume "$docker_repository_root:/repo:ro" \
  "$image_ref" \
  dir --redact /repo >/dev/null

echo "Smoke test concluido: $image_ref"
