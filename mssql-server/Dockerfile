ARG MSSQL_BASE_IMAGE=mcr.microsoft.com/mssql/server@sha256:86cc6144ef39bb0fbed2329e1ad79b13ee82e7b2e4739213a0db0800e668a74a
FROM ${MSSQL_BASE_IMAGE}

LABEL org.opencontainers.image.title="SQL Server 2025 com inicializacao declarativa" \
	  org.opencontainers.image.description="SQL Server 2025 CU7 com bootstrap idempotente de banco, login e scripts" \
	  org.opencontainers.image.source="https://github.com/lzocateli/containers/tree/main/mssql-server" \
	org.opencontainers.image.version="2025-CU7-ubuntu-24.04" \
	org.opencontainers.image.licenses="MIT AND LicenseRef-Microsoft-SQL-Server-EULA"

USER root

RUN install -d -o 10001 -g 10001 -m 0750 /docker-entrypoint-initdb.d

COPY --chown=0:0 --chmod=0644 docker-entrypoint.sh docker-entrypoint-initdb.sh /usr/local/bin/

RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint-initdb.sh \
	&& chmod 0555 /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint-initdb.sh

ENV MSSQL_DATABASE_COLLATE=SQL_Latin1_General_CP1_CI_AI \
	PATH="/opt/mssql-tools18/bin:${PATH}"

EXPOSE 1433
VOLUME ["/var/opt/mssql"]

USER 10001:10001

HEALTHCHECK --start-period=60s --interval=30s --timeout=10s --retries=5 \
	CMD test -f /var/opt/mssql/.container-init-complete && SQLCMDPASSWORD="$MSSQL_SA_PASSWORD" sqlcmd -S localhost -U sa -C -Q "SELECT 1" -b -o /dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/opt/mssql/bin/sqlservr"]
