#!/bin/bash

CONTAINER_NAME=pihole


CRON_ENTRY="0 3 * * 7 /usr/bin/podman exec $CONTAINER_NAME pihole updateGravity > /dev/null"
if ! (crontab -l | grep -q "$CRON_ENTRY"); then
    (crontab -l; echo "$CRON_ENTRY") | crontab -
    echo "Entrada adicionada no crontab"
fi

CRON_ENTRY='0 1 28-31 * * [ "$(date +\%d -d tomorrow)" == "01" ] && /usr/bin/podman exec $CONTAINER_NAME pihole updatePihole > /dev/null'
if ! (crontab -l | grep -q "$CRON_ENTRY"); then
    (crontab -l; echo "$CRON_ENTRY") | crontab -
    echo "Entrada adicionada no crontab"
fi

# Pi-hole: Flush the log daily at 00:00 so it doesn't get out of control
#          Stats will be viewable in the Web interface thanks to the cron job above
#CRON_ENTRY="00 00 * * * /usr/bin/podman exec $CONTAINER_NAME pihole flush > /dev/null"

crontab -l
