#!/bin/sh

# rclone sync /data $RCLONE_DEST -v --create-empty-src-dirs --metadata --modify-window 2s
rclone --config /config/rclone/rclone.conf copy -v --create-empty-src-dirs --metadata --modify-window 2s onedrivelzocateli:/ /data
