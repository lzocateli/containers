#!/bin/sh

echo "Iniciando backup com rclone: $RCLONE_DEST"
# rclone --config /config/rclone/rclone.conf sync -v --create-empty-src-dirs --metadata --modify-window 2s $RCLONE_DEST /data
rclone --config /config/rclone/rclone.conf copy -v --create-empty-src-dirs --metadata --modify-window 2s $RCLONE_DEST /data
echo "Finalizado backup com rclone: $RCLONE_DEST"
echo "------------------------------------------"
