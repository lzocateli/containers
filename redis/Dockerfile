ARG VALKEY_BASE_IMAGE=valkey/valkey@sha256:3acc0687f2a2e1091fae6450d7842dd658c941338cf0a873ddd9e14b9e4ea4dd
FROM ${VALKEY_BASE_IMAGE}

LABEL org.opencontainers.image.title="Valkey 9.1.1" \
	org.opencontainers.image.description="Servidor Valkey compatível com o protocolo Redis e persistência AOF" \
	org.opencontainers.image.source="https://github.com/lzocateli/containers/tree/main/redis" \
	org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/redis" \
	org.opencontainers.image.url="https://hub.docker.com/r/lzocateli/redis" \
	org.opencontainers.image.version="9.1.1" \
	org.opencontainers.image.licenses="BSD-3-Clause"

COPY --chown=0:0 --chmod=0444 valkey.conf /usr/local/etc/valkey/valkey.conf
COPY --chown=0:0 --chmod=0444 users.acl /usr/local/etc/valkey/users.acl
RUN chmod 0555 /usr/local/etc/valkey

EXPOSE 6379

HEALTHCHECK --start-period=10s --interval=30s --timeout=5s --retries=3 \
	CMD ["valkey-cli", "--no-auth-warning", "--user", "healthcheck", "--pass", "healthcheck", "ping"]

USER 999:999

CMD ["valkey-server", "/usr/local/etc/valkey/valkey.conf"]
