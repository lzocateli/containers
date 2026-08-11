#!/bin/bash
# Fix permissions on bind-mounted workspace directory.
# Docker Desktop on Windows maps NTFS ACLs and ignores Linux chmod from WSL,
# so we fix permissions from inside the container (running as root) before
# handing off to the real CloudBeaver launch-product.sh entrypoint.
chmod -R 777 /opt/cloudbeaver/workspace 2>/dev/null || true

# Route corporate traffic through the container's default gateway instead of
# Docker's internal networks. This fixes IP conflicts when corporate servers
# (e.g., Oracle on 172.18.x.x, SQL Server on 10.x.x.x) overlap with Docker
# network ranges. More specific routes (container's own subnet) take precedence.
# Requires: --cap-add=NET_ADMIN
if command -v ip &>/dev/null; then
    GATEWAY=$(ip route | awk '/default/{print $3}')
    if [ -n "$GATEWAY" ]; then
        ip route add 10.0.0.0/8 via "$GATEWAY" 2>/dev/null || true
        ip route add 172.16.0.0/12 via "$GATEWAY" 2>/dev/null || true
        ip route add 192.168.0.0/16 via "$GATEWAY" 2>/dev/null || true
    fi
fi

exec ./launch-product.sh "$@"
