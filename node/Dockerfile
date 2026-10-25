# syntax=docker/dockerfile:1
ARG NODE_VERSION=24.22.1
ARG NPM_VERSION=12.2.1
# undici empacotado no npm 12.2.1 (6.29.0) tem a CVE-2026-109869; corrigida na 6.29.1.
ARG NPM_UNDICI_VERSION=6.29.1

FROM node:${NODE_VERSION}-bookworm AS runtime

ARG NODE_VERSION
ARG NPM_VERSION
ARG NPM_UNDICI_VERSION

LABEL org.opencontainers.image.title="lzocateli/node" \
	org.opencontainers.image.description="Node.js 24 LTS hardened para pipelines e desenvolvimento JavaScript/TypeScript." \
	org.opencontainers.image.source="https://github.com/lzocateli/containers" \
	org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/node" \
	org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/node" \
	org.opencontainers.image.version="${NODE_VERSION}-bookworm"

USER root

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --only-upgrade libgnutls30 libbrotli1 \
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
	&& undici=/usr/local/lib/node_modules/npm/node_modules/undici \
	&& test "$(node -p "require('$undici/package.json').version")" = '6.29.0' \
	&& cd /tmp && npm pack --silent "undici@${NPM_UNDICI_VERSION}" > /dev/null \
	&& rm -rf "$undici" && mkdir "$undici" \
	&& tar -xzf "/tmp/undici-${NPM_UNDICI_VERSION}.tgz" -C "$undici" --strip-components=1 \
	&& rm -f "/tmp/undici-${NPM_UNDICI_VERSION}.tgz" && cd / \
	&& test "$(node -p "require('$undici/package.json').version")" = "${NPM_UNDICI_VERSION}" \
	&& corepack enable \
	&& npm cache clean --force

WORKDIR /workspace
USER node

CMD ["node", "--version"]
