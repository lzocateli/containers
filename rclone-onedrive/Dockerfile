ARG BUILDPLATFORM=linux/amd64

FROM --platform=$BUILDPLATFORM rclone:master

# FROM rclone/rclone

COPY --chmod=755 backup.sh /
COPY --chmod=755 start.sh /
COPY cronjobs /etc/crontabs/root

ENTRYPOINT /bin/sh /start.sh
