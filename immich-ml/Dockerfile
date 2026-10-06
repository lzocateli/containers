# syntax=docker/dockerfile:1
FROM ghcr.io/immich-app/immich-machine-learning:v3.2.4@sha256:e16c2f166a8174901959fdf85e2e4c7bd1ebc4b37e0b6655de97c41408a260c4 AS build

RUN /opt/venv/bin/python -m ensurepip \
  && /opt/venv/bin/python -m pip install --no-cache-dir --no-deps --target /tmp/anyio-patch 'anyio==4.14.2' \
  && test -f /tmp/anyio-patch/anyio-4.14.2.dist-info/METADATA

FROM ghcr.io/immich-app/immich-machine-learning:v3.2.4@sha256:e16c2f166a8174901959fdf85e2e4c7bd1ebc4b37e0b6655de97c41408a260c4 AS runtime

RUN apt-get update \
  && apt-get install -y --no-install-recommends --only-upgrade perl-base \
  && rm -rf /var/lib/apt/lists/*

RUN rm -rf /opt/venv/lib/python3.11/site-packages/anyio /opt/venv/lib/python3.11/site-packages/anyio-4.2.0.dist-info

COPY --from=build /tmp/anyio-patch/anyio /opt/venv/lib/python3.11/site-packages/anyio
COPY --from=build /tmp/anyio-patch/anyio-4.14.2.dist-info /opt/venv/lib/python3.11/site-packages/anyio-4.14.2.dist-info

LABEL org.opencontainers.image.title="lzocateli/immich-ml" \
  org.opencontainers.image.description="Machine learning Immich v3.2.4 (CPU) com AnyIO 4.14.2 para o TrueNAS." \
  org.opencontainers.image.source="https://github.com/lzocateli/containers" \
  org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/immich-ml" \
  org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/immich-ml" \
  org.opencontainers.image.version="v3.2.4-v2"