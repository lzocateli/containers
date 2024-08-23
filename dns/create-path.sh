#!/bin/bash

mkdir -p /userapps/vol-pihole/etc/unbound
mkdir -p /userapps/vol-pihole/etc/pihole
mkdir -p /userapps/vol-pihole/etc/dnsmasq.d
mkdir -p /userapps/var/log/unbound

touch /userapps/var/log/unbound/unbound.log

if [ ! -d "/userapps/secrets" ]; then
    mkdir -p /userapps/secrets
    echo "Teste@1234" >/userapps/secrets/pihole
fi
if podman secret ls | grep -q 'pihole'; then
    echo "Secret 'pihole' já existe."
else
    echo "Criando secret 'pihole' ..."
    podman secret create pihole /userapps/secrets/pihole
    echo "Criado."
fi

cp ./pihole/base/99-edns.conf /userapps/vol-pihole/etc/pihole/
cp ./unbound/unbound.conf /userapps/vol-pihole/etc/unbound/
