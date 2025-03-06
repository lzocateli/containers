ARG BUILDPLATFORM=linux/amd64

FROM --platform=$BUILDPLATFORM rclone/rclone:master

# FROM rclone/rclone

ARG TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone


COPY --chmod=755 backup.sh /
COPY --chmod=755 start.sh /
COPY cronjobs /etc/crontabs/root

ENTRYPOINT /bin/sh /start.sh
