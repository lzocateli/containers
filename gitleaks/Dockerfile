# syntax=docker/dockerfile:1
FROM golang:1.25-alpine@sha256:1e0126852075c9c60731c8ba49088448b91f63e2aed97ca9d1a9791622a05946 AS build

ARG GITLEAKS_VERSION=v8.30.1
ARG X_CRYPTO_VERSION=v0.55.0
ARG X_TEXT_VERSION=v0.41.0

WORKDIR /src

RUN apk add --no-cache git \
  && git clone --depth 1 --branch "${GITLEAKS_VERSION}" https://github.com/gitleaks/gitleaks.git . \
  && go get "golang.org/x/crypto@${X_CRYPTO_VERSION}" "golang.org/x/text@${X_TEXT_VERSION}" \
  && go mod tidy \
  && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w -X github.com/gitleaks/gitleaks/v8/version.Version=${GITLEAKS_VERSION#v}" -o /out/gitleaks . \
  && apk del git

FROM alpine:3.22@sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce

RUN apk upgrade --no-cache

COPY --from=build /out/gitleaks /usr/local/bin/gitleaks

LABEL org.opencontainers.image.title="lzocateli/gitleaks" \
  org.opencontainers.image.description="Gitleaks 8.30.1 para detectar secrets em arquivos, diffs e historico Git." \
  org.opencontainers.image.source="https://github.com/lzocateli/containers" \
  org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/gitleaks" \
  org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/gitleaks" \
  org.opencontainers.image.version="8.30.1" \
  org.opencontainers.image.licenses="MIT"

WORKDIR /repo

ENTRYPOINT ["gitleaks"]
CMD ["version"]
