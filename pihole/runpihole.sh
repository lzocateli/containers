#!/bin/bash

podman rm pihole -f

# PIHOLE_BASE="${PIHOLE_BASE:-$(pwd)}"
PIHOLE_BASE="${PIHOLE_BASE:-/userapps/vol-pihole}"
PIHOLE_LOG="/userapps/var/log/pihole"

if [ ! -d "$PIHOLE_BASE" ]; then
    mkdir -p "${PIHOLE_BASE}/etc/dnsmasq.d"
    mkdir -p "${PIHOLE_BASE}/etc/pihole"
    mkdir -p "${PIHOLE_BASE}/etc/unbound"
fi
if [ ! -d "$PIHOLE_LOG" ] || [ ! -f "${PIHOLE_LOG}/unbound.log" ]; then
    mkdir -p $PIHOLE_LOG
    touch "${PIHOLE_LOG}/unbound.log"
fi
if [ ! -d "/userapps/secrets" ]; then
    mkdir -p /userapps/secrets
fi
if podman secret ls | grep -q 'pihole'; then
    echo "Secret 'pihole' já existe."
else
    echo "Criando secret 'pihole' ..."
    podman secret create pihole /userapps/secrets/pihole
    echo "Criado."
fi

podman run -d \
    --name pihole \
    -p 53:53/tcp \
    -p 53:53/udp \
    -p 80:80 \
    -e TZ="America/Sao_Paulo" \
    -e VIRTUAL_HOST="pi.hole" \
    -e PROXY_LOCATION="pi.hole" \
    -e FTLCONF_LOCAL_IPV4="172.16.10.1" \
    -e WEBPASSWORD_FILE=pihole \
    -e DNSMASQ_LISTENING=all \
    -e DNSSEC=true \
    -v "${PIHOLE_BASE}/etc/pihole:/etc/pihole" \
    -v "${PIHOLE_BASE}/etc/dnsmasq.d:/etc/dnsmasq.d" \
    -v "${PIHOLE_BASE}/etc/unbound/pi-hole.conf:/etc/unbound/unbound.conf.d/pi-hole.conf" \
    -v "${PIHOLE_LOG}/unbound.log:/var/log/unbound/unbound.log" \
    --secret pihole \
    --restart=unless-stopped \
    --hostname pi.hole \
    lzocateli/pihole-unbound:2024.07.0

    # --dns=127.0.0.1 \
    # --dns=1.1.1.1 \

podman ps -a

