# syntax=docker/dockerfile:1
FROM ghcr.io/immich-app/immich-server:v3.2.4@sha256:d317916b28090c33eb36b308464ea391f8b7df1d850fcfea227a39ec879718c2

RUN set -eu; \
  target=/usr/src/app/server/node_modules/.pnpm/tar@7.5.16/node_modules/tar; \
  test "$(node -p "require('$target/package.json').version")" = '7.5.16'; \
  test "$(node -p "require('/usr/local/lib/node_modules/npm/node_modules/tar/package.json').version")" = '7.5.19'; \
  rm -rf "$target"; \
  cp -a /usr/local/lib/node_modules/npm/node_modules/tar "$target"

LABEL org.opencontainers.image.title="lzocateli/immich-server" \
  org.opencontainers.image.description="Servidor Immich v3.2.4 com node-tar 7.5.19 para o TrueNAS." \
  org.opencontainers.image.source="https://github.com/lzocateli/containers" \
  org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/immich-server" \
  org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/immich-server" \
  org.opencontainers.image.version="v3.2.4-r1"