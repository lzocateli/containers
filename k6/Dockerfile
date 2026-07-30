# syntax=docker/dockerfile:1
ARG NODE_BASE_IMAGE=lzocateli/node:24.15.0-bookworm
ARG NODE_VERSION=24.15.0
ARG K6_VERSION=2.1.0
ARG K6_DIGEST=sha256:65c920dc067d5e2e00befbf982af6ad6ad0117034e8b1c65817c7975c52d4669

FROM grafana/k6:${K6_VERSION}@${K6_DIGEST} AS k6-binary

FROM ${NODE_BASE_IMAGE} AS runtime

ARG NODE_VERSION
ARG K6_VERSION

LABEL org.opencontainers.image.title="lzocateli/k6" \
  org.opencontainers.image.description="k6 para testes de carga em scripts JavaScript, empacotado sobre Node.js 24 LTS hardened." \
  org.opencontainers.image.source="https://github.com/lzocateli/containers" \
  org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/k6" \
  org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/k6" \
  org.opencontainers.image.version="${K6_VERSION}-node${NODE_VERSION}-bookworm"

USER root

COPY --from=k6-binary /usr/bin/k6 /usr/local/bin/k6
RUN chmod +x /usr/local/bin/k6

WORKDIR /workspace
USER node

ENTRYPOINT ["k6"]
CMD ["version"]
