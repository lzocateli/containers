#!/usr/bin/env bash
# Entrypoint padrão da imagem infra/devops.
#
# Garante que /opt/venv/bin e /root/.local/bin estejam no PATH para qualquer
# forma de invocação (login, não-login, interativo, não-interativo) — alguns
# /etc/profile resetam o PATH no início.
#
# Se /docker-entrypoint.d/*.sh existir, executa em ordem (hook para projetos
# que precisam fazer setup de runtime — ex.: video-pipeline rodar `uv sync`).
# Cada hook recebe o PATH já corrigido.
#
# Por fim, executa o comando passado (CMD do Dockerfile ou `command:` do compose).
set -euo pipefail

export PATH="/opt/venv/bin:/root/.local/bin:${PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin}"

if [ -d /docker-entrypoint.d ]; then
    for hook in /docker-entrypoint.d/*.sh; do
        [ -e "$hook" ] || continue
        # Hooks são *sourced* (não executados em subshell) para que possam
        # exportar variáveis (ex.: ajustar PATH) que valham para o `exec` final.
        # shellcheck disable=SC1090
        . "$hook"
    done
fi

exec "$@"
