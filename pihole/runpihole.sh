#!/bin/bash

podman rm pihole -f

# https://github.com/pi-hole/docker-pi-hole/blob/master/README.md

# PIHOLE_BASE="${PIHOLE_BASE:-$(pwd)}"
PIHOLE_BASE="${PIHOLE_BASE:-/userapps}"
[[ -d "$PIHOLE_BASE" ]] || mkdir -p "$PIHOLE_BASE" || { echo "Couldn't create storage directory: $PIHOLE_BASE"; exit 1; }

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

# Note: FTLCONF_LOCAL_IPV4 should be replaced with your external ip.
podman run -d \
    --name pihole \
    -p 53:53/tcp \
    -p 53:53/udp \
    -p 80:80 \
    -e TZ="America/Sao_Paulo" \
    -e VIRTUAL_HOST="pi.hole" \
    -e PROXY_LOCATION="pi.hole" \
    -e FTLCONF_LOCAL_IPV4="172.16.10.1" \
    -e WEBPASSWORD= \
    -e WEBPASSWORD_FILE=pihole \
    -e DNSMASQ_LISTENING=all \
    -e DNSSEC=true \
    -v "${PIHOLE_BASE}/etc-pihole:/etc/pihole" \
    -v "${PIHOLE_BASE}/etc-dnsmasq.d:/etc/dnsmasq.d" \
    --dns=127.0.0.1 \
    --dns=1.1.1.2 \
    --restart=unless-stopped \
    --hostname pi.hole \
    pihole/pihole:2024.07.0

podman ps -a
