#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Valida funcionalmente uma imagem Hugo Extended já construída.

Dependências:
  Bash 4.4+ e Docker 24+ com acesso ao daemon.

Uso:
  smoke-test.sh --image REFERENCIA
  smoke-test.sh -h | --help

Parâmetros:
  --image REFERENCIA  Imagem local que será validada, sem valor padrão.
  -h, --help          Exibe esta ajuda e encerra sem executar testes.

Exemplo:
  bash hugo/scripts/smoke-test.sh --image local/hugo:test

Documentação:
  hugo/README.md#validação
EOF
}

fail() {
  echo "erro: $1; consulte --help" >&2
  exit 1
}

image_ref=""
while (($# > 0)); do
  case "$1" in
    --image)
      (($# >= 2)) || fail "--image exige uma referência"
      image_ref="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      fail "argumento desconhecido: $1"
      ;;
  esac
done

[[ -n "$image_ref" ]] || fail "--image é obrigatório"
command -v docker >/dev/null 2>&1 || fail "Docker 24+ não foi encontrado"
docker image inspect "$image_ref" >/dev/null 2>&1 || fail "imagem local não encontrada: $image_ref"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
fixture_dir="$(cd -- "$script_dir/../tests/fixture" && pwd)"
fixture_mount="$fixture_dir"
if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* ]]; then
  fixture_mount="$(cygpath -w "$fixture_dir")"
  export MSYS_NO_PATHCONV=1
fi

output_volume="hugo-smoke-${RANDOM}-$$"
docker volume create "$output_volume" >/dev/null
trap 'docker volume rm --force "$output_volume" >/dev/null 2>&1 || true' EXIT

configured_user="$(docker image inspect --format '{{.Config.User}}' "$image_ref")"
[[ "$configured_user" == "hugo" ]] || fail "usuário padrão inesperado: ${configured_user:-root}"

version_output="$(docker run --rm --read-only "$image_ref" version)"
[[ "$version_output" == *"v0.165.0-DEV-8a468df"* ]] || fail "versão Hugo inesperada: $version_output"
[[ "$version_output" == *"extended"* ]] || fail "a edição Hugo Extended é obrigatória"

runtime_uid="$(docker run --rm --read-only --entrypoint id "$image_ref" -u)"
runtime_gid="$(docker run --rm --read-only --entrypoint id "$image_ref" -g)"
docker run --rm \
  --user 0:0 \
  --volume "$output_volume:/out" \
  --entrypoint /bin/sh \
  "$image_ref" \
  -c "chown $runtime_uid:$runtime_gid /out"

docker run --rm \
  --read-only \
  --tmpfs /tmp:rw,nosuid,nodev,noexec,size=64m \
  --volume "$fixture_mount:/src:ro" \
  --volume "$output_volume:/out:rw" \
  "$image_ref" \
  --source /src \
  --destination /out \
  --cleanDestinationDir \
  --noBuildLock \
  --minify

docker run --rm \
  --read-only \
  --volume "$output_volume:/out:ro" \
  --entrypoint /bin/sh \
  "$image_ref" \
  -c 'test -f /out/index.html && grep -Fq "<title>Hugo Extended smoke test</title>" /out/index.html && find /out -type f -name "main.min.*.css" -print -quit | grep -q .' \
  || fail "os artefatos HTML e CSS esperados não foram gerados"

echo "Smoke test concluído: $image_ref"