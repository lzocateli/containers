ARG BUILDPLATFORM=linux/amd64

FROM --platform=$BUILDPLATFORM rclone/rclone:master

ARG TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone

ENV LOG_FILE_NAME=bkp

RUN mkdir -p /userapps/utils
COPY --chmod=755 backup.sh /userapps/utils/
COPY --chmod=755 start.sh /userapps/utils/
COPY cronjobs /etc/crontabs/root

ENTRYPOINT /bin/sh /userapps/utils/start.sh
