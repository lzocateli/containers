# syntax=docker/dockerfile:1
FROM golang:1.27.1-bookworm@sha256:69a7b9788769bec032d238959b61854e9ae87f57be9029ec04e9885fabf99195 AS build

ADD https://github.com/tianon/gosu.git#6456aaa0f3c854d199d0f037f068eb97515b7513 /src/gosu
WORKDIR /src/gosu
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /opt/gosu . \
  && /opt/gosu --version

FROM ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23 AS runtime

RUN apt-get update \
  && apt-get install -y --no-install-recommends --only-upgrade libgnutls30 libssl3 openssl libperl5.36 perl perl-base perl-modules-5.36 \
  && rm -rf /var/lib/apt/lists/*

COPY --from=build --chmod=0755 /opt/gosu /usr/local/bin/gosu

LABEL org.opencontainers.image.title="lzocateli/immich-postgres" \
  org.opencontainers.image.description="PostgreSQL 14 com VectorChord 0.4.3, pgvectors 0.2.0 e correcoes de seguranca para Immich." \
  org.opencontainers.image.source="https://github.com/lzocateli/containers" \
  org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/immich-postgres" \
  org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/immich-postgres" \
  org.opencontainers.image.version="14-vc0.4.3-pgv0.2.0-v2"