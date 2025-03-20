ARG BUILDPLATFORM=linux/amd64

FROM --platform=$BUILDPLATFORM rclone/rclone:master

ARG TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone

RUN apk add --no-interactive openrc cronie python3 py3-pip

ENV LOG_FILE_NAME=bkp

RUN mkdir -p /userapps/utils
COPY --chmod=771 backup.sh /userapps/utils/
COPY --chmod=771 start.sh /userapps/utils/
COPY --chmod=771 proxima_execucao.py /userapps/utils/
COPY cronjobs /etc/crontabs/root
COPY requirements.txt /tmp/requirements.txt

RUN python3 -m venv /userapps/utils/venv \
    && /userapps/utils/venv/bin/pip install --no-cache-dir --upgrade pip \
    && /userapps/utils/venv/bin/pip install -r /tmp/requirements.txt
    
ENV PATH="/userapps/utils/venv/bin:$PATH"

ENTRYPOINT /bin/sh /userapps/utils/start.sh
