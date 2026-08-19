# syntax=docker/dockerfile:1
FROM zricethezav/gitleaks:v8.30.1@sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f

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
