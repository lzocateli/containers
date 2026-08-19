# syntax=docker/dockerfile:1
ARG IMAGE_VERSION=3.14-bookworm

FROM python:${IMAGE_VERSION} AS buildbase

LABEL org.opencontainers.image.title="Python" \
      org.opencontainers.image.description="Python 3.14 com ambiente base para automação, scripts e aplicações leves com UV instalado." \
      org.opencontainers.image.source="https://github.com/lzocateli/containers" \
      org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/python" \
      org.opencontainers.image.url="https://hub.docker.com/r/lzocateli/python" \
      org.opencontainers.image.version="3.14-bookworm"

RUN apt-get update -y \
    && apt-get install --no-install-recommends -y ca-certificates curl tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/bin" sh \
    && uv --version

WORKDIR /workspace

ENTRYPOINT ["python3"]
CMD ["--version"]
