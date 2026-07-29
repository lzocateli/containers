ARG KEYCLOAK_BASE_IMAGE=quay.io/keycloak/keycloak@sha256:26939e1318d6f008fc2ee6e10cec1cf8f1ba8a21846c1bc81b91ed0506bc2a7a
FROM ${KEYCLOAK_BASE_IMAGE}

LABEL org.opencontainers.image.title="Keycloak 26.7.0" \
	  org.opencontainers.image.description="Keycloak configuravel em runtime para PostgreSQL ou Microsoft SQL Server" \
	  org.opencontainers.image.source="https://github.com/lzocateli/containers/tree/main/keycloak" \
	  org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/keycloak" \
	  org.opencontainers.image.version="26.7.0" \
	  org.opencontainers.image.licenses="Apache-2.0"

ENV KC_HEALTH_ENABLED=true \
	KC_METRICS_ENABLED=true

EXPOSE 8080 8443 9000

USER 1000

HEALTHCHECK --start-period=60s --interval=30s --timeout=5s --retries=5 \
	CMD ["bash", "-c", "exec 3<>/dev/tcp/127.0.0.1/9000 && printf 'GET /health/ready HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n' >&3 && read -r status <&3 && [[ \"$status\" == *\" 200 \"* ]]"]
