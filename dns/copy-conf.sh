#!/bin/bash

   if [ ! -f "/userapps/vol-pihole/etc/pihole/99-edns.conf" ]; then
       cp ./pihole/base/99-edns.conf /userapps/vol-pihole/etc/pihole/
   fi
   if [ ! -f "/userapps/vol-pihole/etc/unbound/unbound.conf" ]; then
       cp ./unbound/unbound.conf /userapps/vol-pihole/etc/unbound/
   fi

