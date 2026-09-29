# syntax=docker/dockerfile:1
ARG NEXTCLOUD_VERSION=35.0.1
ARG NEXTCLOUD_BASE=nextcloud:${NEXTCLOUD_VERSION}-apache@sha256:276547e033df451770dbf9c0065929e5ea179a613b1884bd3fa807ba1c2703e7

FROM ${NEXTCLOUD_BASE}

ARG NEXTCLOUD_VERSION

LABEL org.opencontainers.image.title="lzocateli/nextcloud" \
  org.opencontainers.image.description="Nextcloud Community Apache com a imagem upstream fixada por versao e digest." \
  org.opencontainers.image.source="https://github.com/lzocateli/containers" \
  org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/nextcloud" \
  org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/nextcloud" \
  org.opencontainers.image.version="${NEXTCLOUD_VERSION}-r1"

HEALTHCHECK --interval=30s --timeout=5s --start-period=10m --retries=3 \
  CMD ["php", "-r", "$headers = @get_headers('http://127.0.0.1/status.php'); exit(($headers && str_contains($headers[0], '200')) ? 0 : 1);"]