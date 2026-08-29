# syntax=docker/dockerfile:1
ARG PLAYWRIGHT_VERSION=1.49.0
ARG UV_VERSION=0.5.18
ARG IMAGE_VERSION=0.1.0

FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv

FROM mcr.microsoft.com/playwright/python:v${PLAYWRIGHT_VERSION}-noble AS runtime

ARG PLAYWRIGHT_VERSION
ARG IMAGE_VERSION

LABEL org.opencontainers.image.title="lzocateli/playwright-e2e" \
    org.opencontainers.image.description="Base para testes E2E Python com Playwright, pytest e suporte opcional a WireGuard." \
    org.opencontainers.image.source="https://github.com/lzocateli/containers" \
    org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/playwright-e2e" \
    org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/playwright-e2e" \
    org.opencontainers.image.version="${IMAGE_VERSION}"

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    curl \
    iproute2 \
    iptables \
    resolvconf \
    wireguard-tools \
    && rm -rf /var/lib/apt/lists/*

COPY --from=uv /uv /usr/local/bin/uv

WORKDIR /app

COPY pyproject.toml .python-version ./
RUN uv sync --no-dev --no-install-project \
    && uv run playwright install --with-deps chromium firefox webkit \
    && mkdir -p /app/reports /app/tests /app/src/e2e /app/src/vpn /app/vpn/configs

ENV PYTHONPATH=/app/src

ENTRYPOINT ["uv", "run", "--frozen", "pytest", "--confcutdir=/app"]
CMD ["--base-url=http://host.containers.internal:1313"]