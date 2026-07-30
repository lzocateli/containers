# syntax=docker/dockerfile:1
ARG NODE_BASE_IMAGE=lzocateli/node:24.15.0-bookworm
ARG NODE_VERSION=24.15.0
ARG ANGULAR_CLI_VERSION=22.1.0
ARG NPM_VERSION=12.0.2

FROM ${NODE_BASE_IMAGE} AS runtime

ARG NODE_VERSION
ARG ANGULAR_CLI_VERSION
ARG NPM_VERSION

LABEL org.opencontainers.image.title="lzocateli/angular-cli" \
  org.opencontainers.image.description="Angular CLI 22 sobre Node.js 24 LTS para scaffolding, build e desenvolvimento de projetos Angular." \
  org.opencontainers.image.source="https://github.com/lzocateli/containers" \
  org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/angular-cli" \
  org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/angular-cli" \
  org.opencontainers.image.version="${ANGULAR_CLI_VERSION}-node${NODE_VERSION}-bookworm"

ENV NG_CLI_ANALYTICS=false \
  NPM_CONFIG_UPDATE_NOTIFIER=false

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
  && npm install --global "@angular/cli@${ANGULAR_CLI_VERSION}" \
  && npm cache clean --force

COPY docker-entrypoint.sh /usr/local/bin/angular-entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/angular-entrypoint.sh \
  && chmod +x /usr/local/bin/angular-entrypoint.sh

WORKDIR /workspace
USER node

EXPOSE 4200

ENTRYPOINT ["/usr/local/bin/angular-entrypoint.sh"]
CMD ["ng", "version"]
