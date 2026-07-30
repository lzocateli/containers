# syntax=docker/dockerfile:1
ARG NODE_VERSION=24.15.0

FROM node:${NODE_VERSION}-bookworm AS runtime

ARG NODE_VERSION

LABEL org.opencontainers.image.title="lzocateli/node" \
	org.opencontainers.image.description="Node.js LTS para pipelines e desenvolvimento com suporte ao ecossistema Angular 22." \
	org.opencontainers.image.source="https://github.com/lzocateli/containers" \
	org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/node" \
	org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/node" \
	org.opencontainers.image.version="${NODE_VERSION}-bookworm"

RUN corepack enable

WORKDIR /workspace
USER node

CMD ["node", "--version"]
