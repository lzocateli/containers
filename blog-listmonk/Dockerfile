FROM listmonk/listmonk:v6.2.0

USER root

ENV TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /listmonk

COPY ./config.toml /listmonk/config.toml

EXPOSE 9000
