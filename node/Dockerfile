# syntax=docker/dockerfile:1
ARG NODE_VERSION=24.15.0
ARG NPM_VERSION=12.0.2

FROM node:${NODE_VERSION}-bookworm AS runtime

ARG NODE_VERSION
ARG NPM_VERSION

LABEL org.opencontainers.image.title="lzocateli/node" \
	org.opencontainers.image.description="Node.js LTS para pipelines e desenvolvimento com suporte ao ecossistema Angular 22." \
	org.opencontainers.image.source="https://github.com/lzocateli/containers" \
	org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/node" \
	org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/node" \
	org.opencontainers.image.version="${NODE_VERSION}-bookworm"

USER root

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --only-upgrade libgnutls30 \
	&& DEBIAN_FRONTEND=noninteractive apt-get purge -y --auto-remove \
		imagemagick \
		imagemagick-6-common \
		imagemagick-6.q16 \
		libmagickcore-dev \
		libmagickcore-6.q16-dev \
		libmagickwand-dev \
		libmagickwand-6.q16-dev \
		libmariadb-dev \
		libmariadb-dev-compat \
		libmariadb3 \
		mariadb-common \
		linux-libc-dev \
	&& rm -rf /var/lib/apt/lists/* \
	&& npm install --global "npm@${NPM_VERSION}" \
	&& corepack enable \
	&& npm cache clean --force

WORKDIR /workspace
USER node

CMD ["node", "--version"]
