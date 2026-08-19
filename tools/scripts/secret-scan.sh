#!/usr/bin/env bash
set -Eeuo pipefail

PROGRAM_NAME=""
SCRIPT_DIR=""
readonly GITLEAKS_IMAGE="lzocateli/gitleaks:8.30.1"
REPOSITORY_ROOT=""
PROGRAM_NAME="$(basename -- "$0")"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPOSITORY_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
readonly PROGRAM_NAME SCRIPT_DIR REPOSITORY_ROOT
DRY_RUN=false
MODE="history"
TARGET=""
LOG_FILE=""
REPORT_FILE=""
REWRITE_PATHS=()
REPLACE_TEXT_FILE=""
CONFIRM_REWRITE=false

show_help() {
  cat <<EOF
Uso: ${PROGRAM_NAME} [OPCOES]

O que faz:
  Detecta credenciais com Gitleaks no historico Git, no indice staged ou em um
  diretorio. O modo history examina todas as referencias locais (--all).

Dependencias:
  Bash 5.1 ou superior; Git; Gitleaks 8.30.1 ou Docker com acesso ao daemon.
  Se o executavel gitleaks nao existir, o fallback usa ${GITLEAKS_IMAGE}.
  No Windows, Git Bash/WSL usa docker.exe e um bind mount somente leitura.

Opcoes:
  --history          Examina todo o historico Git (padrao).
  --staged           Examina somente o conteudo preparado para commit.
  --dir CAMINHO      Examina arquivos do caminho informado.
  --rewrite-history  Remove caminhos ou substitui secrets no historico Git.
  --path CAMINHO     Caminho relativo a remover de todas as refs; repetivel.
  --replace-text ARQ  Arquivo do git-filter-repo com substituicoes; nao e logado.
  --confirm-rewrite  Confirma a operacao destrutiva fora do dry-run.
  -n, --dry-run      Mostra a verificacao planejada sem executar o scanner.
  -h, --help         Exibe esta ajuda e encerra.

Saidas e codigos:
  O log fica em .tmp/${PROGRAM_NAME}-YYYYmmdd-HHMMSS-PID.log.
  Achados sao listados sem o segredo e salvos em .tmp como JSON redigido.
  Retorna 0 sem achados, 1 quando Gitleaks encontra achados ou falha, e 2 para
  uso invalido. O scanner usa --redact para nao gravar o valor do segredo.

Exemplos:
  ${PROGRAM_NAME} --help
  ${PROGRAM_NAME} --dry-run
  ${PROGRAM_NAME} --staged
  ${PROGRAM_NAME} --dir .
  ${PROGRAM_NAME} --rewrite-history --path config/prod.env --confirm-rewrite
  ${PROGRAM_NAME} --rewrite-history --replace-text replacements.txt --confirm-rewrite
  git config core.hooksPath .githooks

Documentacao:
  docs/SECRET-SCANNING.md
EOF
}

log() {
  local level="$1"
  shift
  printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a -- "$LOG_FILE"
}

log_error() {
  local message="$*"
  printf '[%s] [ERROR] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" | tee -a -- "$LOG_FILE" >&2
}

fail_usage() {
  printf 'Erro: %s\nConsulte %s --help.\n' "$1" "$PROGRAM_NAME" >&2
  exit 2
}

while (($# > 0)); do
  case "$1" in
    --history)
      MODE="history"
      shift
      ;;
    --staged)
      MODE="staged"
      shift
      ;;
    --dir)
      (($# >= 2)) || fail_usage "--dir exige um caminho"
      MODE="dir"
      TARGET="$2"
      shift 2
      ;;
    --rewrite-history)
      MODE="rewrite"
      shift
      ;;
    --path)
      (($# >= 2)) || fail_usage "--path exige um caminho relativo"
      REWRITE_PATHS+=("$2")
      shift 2
      ;;
    --replace-text)
      (($# >= 2)) || fail_usage "--replace-text exige um arquivo"
      REPLACE_TEXT_FILE="$2"
      shift 2
      ;;
    --confirm-rewrite)
      CONFIRM_REWRITE=true
      shift
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      fail_usage "parametro desconhecido: $1"
      ;;
  esac
done

mkdir -p -- "$REPOSITORY_ROOT/.tmp"
LOG_FILE="$REPOSITORY_ROOT/.tmp/${PROGRAM_NAME}-$(date '+%Y%m%d-%H%M%S')-$$.log"
REPORT_FILE="$REPOSITORY_ROOT/.tmp/${PROGRAM_NAME}-$(date '+%Y%m%d-%H%M%S')-$$.json"
touch -- "$LOG_FILE"
trap 'log INFO "Encerrando com codigo $?; log: $LOG_FILE"' EXIT

log INFO "Inicio: modo=$MODE dry_run=$DRY_RUN repositorio=$REPOSITORY_ROOT"

if [[ "$MODE" == "dir" && ! -e "$TARGET" ]]; then
  log_error "Caminho inexistente: $TARGET"
  exit 2
fi

if [[ "$MODE" == "rewrite" ]]; then
  [[ ${#REWRITE_PATHS[@]} -gt 0 || -n "$REPLACE_TEXT_FILE" ]] || fail_usage "--rewrite-history exige --path ou --replace-text"
  if [[ -n "$REPLACE_TEXT_FILE" && ! -f "$REPLACE_TEXT_FILE" ]]; then
    log_error "Arquivo de substituicao inexistente: $REPLACE_TEXT_FILE"
    exit 2
  fi
  for rewrite_path in "${REWRITE_PATHS[@]}"; do
    case "$rewrite_path" in
      /*|.|..|../*|*/../*)
        log_error "--path deve ser relativo ao repositorio e nao pode conter subida de diretorio: $rewrite_path"
        exit 2
        ;;
    esac
  done
  if [[ "$DRY_RUN" != "true" ]]; then
    [[ "$CONFIRM_REWRITE" == "true" ]] || fail_usage "a reescrita exige --confirm-rewrite"
    [[ -z "$(git -c core.autocrlf=true status --porcelain)" ]] || {
      log_error "A reescrita exige working tree limpo; salve ou descarte alteracoes primeiro."
      exit 1
    }
  fi
  FILTER_ARGS=(--force)
  if ((${#REWRITE_PATHS[@]} > 0)); then
    FILTER_ARGS+=(--invert-paths)
    for rewrite_path in "${REWRITE_PATHS[@]}"; do
      FILTER_ARGS+=(--path "$rewrite_path")
    done
  fi
  if [[ -n "$REPLACE_TEXT_FILE" ]]; then
    FILTER_ARGS+=(--replace-text "$REPLACE_TEXT_FILE")
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    log INFO "[DRY-RUN] Reescrita planejada: git ${FILTER_ARGS[*]}"
    exit 0
  fi
  if command -v git-filter-repo >/dev/null 2>&1; then
    FILTER_REPO_COMMAND=git-filter-repo
  elif command -v git-filter-repo.exe >/dev/null 2>&1; then
    FILTER_REPO_COMMAND=git-filter-repo.exe
  else
    log_error "git-filter-repo nao foi encontrado. Instale-o antes da reescrita."
    exit 1
  fi
  log WARN "Reescrevendo historico; remotes e clones existentes exigirao coordenacao."
  "$FILTER_REPO_COMMAND" "${FILTER_ARGS[@]}"
  log INFO "Historico reescrito. Revogue credenciais, force push autorizado e execute --history novamente."
  exit 0
fi

if command -v gitleaks >/dev/null 2>&1; then
  SCANNER=(gitleaks)
  log INFO "Scanner: executavel local"
elif command -v docker.exe >/dev/null 2>&1 || command -v docker >/dev/null 2>&1; then
  export MSYS_NO_PATHCONV=1
  export MSYS2_ARG_CONV_EXCL='*'
  if command -v docker.exe >/dev/null 2>&1; then
    DOCKER_COMMAND=docker.exe
  else
    DOCKER_COMMAND=docker
  fi
  if command -v wslpath >/dev/null 2>&1; then
    DOCKER_REPOSITORY_ROOT="$(wslpath -w "$REPOSITORY_ROOT")"
  elif command -v cygpath >/dev/null 2>&1; then
    DOCKER_REPOSITORY_ROOT="$(cygpath -w "$REPOSITORY_ROOT")"
  else
    DOCKER_REPOSITORY_ROOT="$REPOSITORY_ROOT"
  fi
  SCANNER=("$DOCKER_COMMAND" run --rm -v "$DOCKER_REPOSITORY_ROOT:/repo:ro" -v "$DOCKER_REPOSITORY_ROOT/.tmp:/reports:rw" -w /repo "$GITLEAKS_IMAGE")
  log INFO "Scanner: Docker $GITLEAKS_IMAGE"
else
  log_error "Nem gitleaks nem Docker estao disponiveis. Consulte --help."
  exit 1
fi

case "$MODE" in
  history)
    SCAN_ARGS=(git --redact --report-format json --report-path "/reports/$(basename -- "$REPORT_FILE")" --log-opts="--all" .)
    ;;
  staged)
    SCAN_ARGS=(stdin --redact --report-format json --report-path "/reports/$(basename -- "$REPORT_FILE")")
    ;;
  dir)
    SCAN_ARGS=(dir --redact --report-format json --report-path "/reports/$(basename -- "$REPORT_FILE")" "$TARGET")
    ;;
esac

if [[ "$DRY_RUN" == "true" ]]; then
  log INFO "[DRY-RUN] Scanner planejado: ${SCANNER[*]} ${SCAN_ARGS[*]}"
  exit 0
fi

if [[ "${SCANNER[0]}" == "gitleaks" ]]; then
  SCAN_ARGS+=(--report-path "$REPORT_FILE")
fi

log INFO "Executando Gitleaks; achados serao redigidos na saida."
set +e
if [[ "$MODE" == "staged" ]]; then
  git diff --cached --binary | "${SCANNER[@]}" "${SCAN_ARGS[@]}" 2>&1 | tee -a -- "$LOG_FILE"
  scan_status=${PIPESTATUS[1]}
else
  "${SCANNER[@]}" "${SCAN_ARGS[@]}" 2>&1 | tee -a -- "$LOG_FILE"
  scan_status=${PIPESTATUS[0]}
fi
set -e

if ((scan_status != 0)); then
  if command -v jq >/dev/null 2>&1 && [[ -s "$REPORT_FILE" ]]; then
    log WARN "Achados redigidos (caminho, commit, regra e linha):"
    jq -r '.[] | "path=\(.File) commit=\(.Commit) rule=\(.RuleID) line=\(.StartLine)"' "$REPORT_FILE" | tee -a -- "$LOG_FILE"
  elif command -v python3 >/dev/null 2>&1 && [[ -s "$REPORT_FILE" ]]; then
    log WARN "Achados redigidos (caminho, commit, regra e linha):"
    python3 - "$REPORT_FILE" <<'PY' | tee -a -- "$LOG_FILE"
import json
import sys

for finding in json.load(open(sys.argv[1], encoding="utf-8")):
    print(
        f"path={finding.get('File', '')} "
        f"commit={finding.get('Commit', '')} "
        f"rule={finding.get('RuleID', '')} "
        f"line={finding.get('StartLine', '')}"
    )
PY
  else
    log WARN "Relatorio redigido: $REPORT_FILE. Instale jq ou python3 para listar os caminhos no console."
  fi
  log_error "Gitleaks encontrou achados ou falhou (codigo $scan_status). Revogue credenciais reais antes de limpar o historico."
  exit 1
fi

log INFO "Nenhum segredo detectado."