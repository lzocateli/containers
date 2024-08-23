#!/bin/bash

if [ "$EUID" -eq 0 ]; then
   echo "Executando como root"

   mkdir -p /userapps/vol-pihole/etc/unbound
   mkdir -p /userapps/vol-pihole/etc/pihole
   mkdir -p /userapps/vol-pihole/etc/dnsmasq.d
   mkdir -p /userapps/var/log/unbound

   touch /userapps/var/log/unbound/unbound.log


   if [ ! -d "/userapps/secrets" ]; then
       mkdir -p /userapps/secrets
       echo "Teste@1234" >/userapps/secrets/pihole
       chown -R brazildevops:users /userapps/secrets
   fi

   chown -R brazildevops:users /userapps/vol-pihole
   chmod -R 777 /userapps/vol-pihole/etc
   chown -R brazildevops:users /userapps/var/log/unbound
   chmod -R 777 /userapps/var/log/unbound

   echo "Concluido"
else
   echo "Executando como $EUID"

   if podman secret ls | grep -q 'pihole'; then
      echo "Secret 'pihole' já existe."
   else
      echo "Criando secret 'pihole' ..."
      podman secret create pihole /userapps/secrets/pihole
      echo "Criado."
   fi

   if [ ! -f "/userapps/vol-pihole/etc/pihole/99-edns.conf" ]; then
       cp ./pihole/base/99-edns.conf /userapps/vol-pihole/etc/pihole/
   fi
   if [ ! -f "/userapps/vol-pihole/etc/unbound/unbound.conf" ]; then
       cp ./unbound/unbound.conf /userapps/vol-pihole/etc/unbound/
   fi

   if ! podman network exists dns_net; then
      echo "Criando rede podman"
      podman network create --driver bridge --subnet 172.16.53.0/29 dns_net

      echo "Edite o arquivo: nano /home/brazildevops/.config/cni/net.d/dns_net.conflist"
      echo "Altere a versao do cniVersion para 0.4.0"
   else
      echo "Rede dns_net ja existe"
   fi

   echo "Concluido"
fi
