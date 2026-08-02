# syntax=docker/dockerfile:1

FROM docker.io/hugomods/hugo:nightly-non-root@sha256:1a2d68357bada338e716248cb448f61a4bab9de7180a2ae2a07e25bc31f08822

LABEL org.opencontainers.image.title="Hugo Extended" \
      org.opencontainers.image.description="Hugo Extended reproduzível para construir os sites Blog zocate.li e ThothisIT" \
      org.opencontainers.image.source="https://github.com/lzocateli/containers" \
      org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/hugo" \
      org.opencontainers.image.url="https://hub.docker.com/r/lzocateli/hugo" \
      org.opencontainers.image.version="exts-0.165.0-dev.8a468df-1"

USER root

RUN npm install --global --ignore-scripts --no-audit --no-fund npm@12.0.2 \
    && npm cache clean --force

WORKDIR /src

USER hugo

EXPOSE 1313