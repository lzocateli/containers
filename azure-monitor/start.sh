#!/usr/bin/env bash
set -euo pipefail

if [ -z "${WORKSPACE_ID:-}" ] || [ -z "${WORKSPACE_KEY:-}" ]; then
  echo "Defina WORKSPACE_ID e WORKSPACE_KEY somente em runtime para fazer o onboarding do Azure Monitor." >&2
  exit 1
fi

if [ ! -x /opt/microsoft/omsagent/bin/service_control ]; then
  installer=/tmp/onboard_agent.sh
  curl -fsSL https://raw.githubusercontent.com/microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh -o "$installer"
  chmod 0755 "$installer"
  "$installer" -w "$WORKSPACE_ID" -s "$WORKSPACE_KEY"
  rm -f "$installer"
fi

exec "$@"
