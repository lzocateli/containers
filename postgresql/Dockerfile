FROM pgvector/pgvector:0.8.5-pg18-bookworm

LABEL org.opencontainers.image.title="lzocateli/postgresql" \
	org.opencontainers.image.description="PostgreSQL 18 com pgvector para uso em contêineres." \
	org.opencontainers.image.source="https://github.com/lzocateli/containers" \
	org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/postgresql" \
	org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/postgresql"

ENV POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=C.UTF-8"

EXPOSE 5432

COPY postgresql-healthcheck.sh /usr/local/bin/postgresql-healthcheck

RUN chmod +x /usr/local/bin/postgresql-healthcheck

# O entrypoint oficial da imagem base inicializa o cluster e executa scripts
# montados em /docker-entrypoint-initdb.d de forma síncrona no primeiro bootstrap.
