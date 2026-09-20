# syntax=docker/dockerfile:1
ARG BASE_IMAGE=lzocateli/nginx:1.28.0-bookworm

FROM ${BASE_IMAGE}

ARG NGINX_ANGULAR_VERSION=1.28.0-bookworm-r2

LABEL org.opencontainers.image.title="lzocateli/nginx-angular" \
  org.opencontainers.image.description="NGINX para aplicações Angular, com fragmentos reutilizáveis de configuração de proxy e compressão." \
  org.opencontainers.image.source="https://github.com/lzocateli/containers" \
  org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/nginx-angular" \
  org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/nginx-angular" \
  org.opencontainers.image.version="${NGINX_ANGULAR_VERSION}"

COPY Common/*.conf /etc/nginx/conf.d/