#!/usr/bin/env bash
# Entrypoint padrao da imagem infra/devops.
#
# Garante que /opt/venv/bin e /root/.local/bin estejam no PATH para qualquer
# forma de invocacao (login, nao-login, interativo, nao-interativo).
#
# Se /docker-entrypoint.d/*.sh existir, executa em ordem.
# Cada hook recebe o PATH ja corrigido.
#
# Por fim, executa o comando passado (CMD do Dockerfile ou `command:` do compose).
set -euo pipefail

export PATH="/opt/venv/bin:/root/.local/bin:${PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin}"

if [ -d /docker-entrypoint.d ]; then
    for hook in /docker-entrypoint.d/*.sh; do
        [ -e "$hook" ] || continue
        # Hooks sao *sourced* (nao executados em subshell) para que possam
        # exportar variaveis (ex.: ajustar PATH) que valham para o `exec` final.
        # shellcheck disable=SC1090
        . "$hook"
    done
fi

exec "$@"
