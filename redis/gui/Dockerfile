ARG REDIS_GUI_BASE_IMAGE=patrikx3/p3x-redis-ui@sha256:e48c3b53d243db9d629edafd7b2f28c19038bd2ce944cfd2e8bf035c8baa3d79
FROM ${REDIS_GUI_BASE_IMAGE}

LABEL org.opencontainers.image.title="P3X Redis UI 2026.4.3014" \
	org.opencontainers.image.description="Interface web para administrar servidores compatíveis com o protocolo Redis" \
	org.opencontainers.image.source="https://github.com/lzocateli/containers/tree/main/redis/gui" \
	org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/redis/gui" \
	org.opencontainers.image.url="https://hub.docker.com/r/lzocateli/redis-gui" \
	org.opencontainers.image.version="2026.4.3014" \
	org.opencontainers.image.licenses="MIT"

RUN mkdir -p /settings \
	&& chown 10001:0 /settings \
	&& chmod 0770 /settings

EXPOSE 7843

USER 10001:0
