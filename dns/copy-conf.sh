#!/bin/bash

   if [ ! -f "/userapps/vol-pihole/etc/pihole/99-edns.conf" ]; then
       cp ./pihole/base/99-edns.conf /userapps/vol-pihole/etc/pihole/
       chown brazildevops:brazildevops /userapps/vol-pihole/etc/pihole/99-edns.conf
   fi
   if [ ! -f "/userapps/vol-pihole/etc/unbound/unbound.conf" ]; then
       cp ./unbound/unbound.conf /userapps/vol-pihole/etc/unbound/
       chown brazildevops:brazildevops /userapps/vol-pihole/etc/unbound/unbound.conf
   fi

touch /userapps/var/log/unbound/unbound.log
chown brazildevops:brazildevops /userapps/var/log/unbound/unbound.log
