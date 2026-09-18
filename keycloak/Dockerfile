ARG KEYCLOAK_BASE_IMAGE=quay.io/keycloak/keycloak@sha256:c2a17fe407e892196d0b7cf9cef54e60952d6c372a9205f661a9efa0911463b0
FROM ${KEYCLOAK_BASE_IMAGE}

LABEL org.opencontainers.image.title="Keycloak 26.7.2" \
	  org.opencontainers.image.description="Keycloak configuravel em runtime para PostgreSQL ou Microsoft SQL Server" \
	  org.opencontainers.image.source="https://github.com/lzocateli/containers/tree/main/keycloak" \
	  org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/keycloak" \
	  org.opencontainers.image.version="26.7.2" \
	  org.opencontainers.image.licenses="Apache-2.0"

ENV KC_HEALTH_ENABLED=true \
	KC_METRICS_ENABLED=true

EXPOSE 8080 8443 9000

USER 1000

HEALTHCHECK --start-period=60s --interval=30s --timeout=5s --retries=5 \
	CMD ["bash", "-c", "exec 3<>/dev/tcp/127.0.0.1/9000 && printf 'GET /health/ready HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n' >&3 && read -r status <&3 && [[ \"$status\" == *\" 200 \"* ]]"]
