# syntax=docker/dockerfile:1

ARG POSTGRES_BASE_IMAGE="postgres:18.4-bookworm@sha256:882236b897e39051d2368c5ccc6cda944904723506b2dfc97f2a8f5bc9afa382"

FROM ${POSTGRES_BASE_IMAGE} AS build

ARG PGVECTOR_COMMIT="8ee86c96f0fd72390f890aa8a336fda6d3ab4c6c"

ADD https://github.com/pgvector/pgvector.git#${PGVECTOR_COMMIT} /tmp/pgvector

RUN apt-get update \
	&& apt-mark hold locales \
	&& apt-get install --yes --no-install-recommends build-essential postgresql-server-dev-18 \
	&& cd /tmp/pgvector \
	&& make clean \
	&& make OPTFLAGS="" \
	&& make install \
	&& install --directory /opt/pgvector/lib /opt/pgvector/extension /opt/pgvector/doc \
	&& cp /usr/lib/postgresql/18/lib/vector.so /opt/pgvector/lib/ \
	&& cp /usr/share/postgresql/18/extension/vector* /opt/pgvector/extension/ \
	&& cp LICENSE README.md /opt/pgvector/doc/

FROM ${POSTGRES_BASE_IMAGE} AS runtime

ARG IMAGE_VERSION="18.4-pgvector0.8.6-bookworm"

COPY --from=build /opt/pgvector/lib/vector.so /usr/lib/postgresql/18/lib/vector.so
COPY --from=build /opt/pgvector/extension/ /usr/share/postgresql/18/extension/
COPY --from=build /opt/pgvector/doc/ /usr/share/doc/pgvector/

LABEL org.opencontainers.image.title="lzocateli/postgresql" \
	org.opencontainers.image.description="PostgreSQL 18 com pgvector para uso em contêineres." \
	org.opencontainers.image.source="https://github.com/lzocateli/containers" \
	org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/postgres" \
	org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/postgres" \
	org.opencontainers.image.version="${IMAGE_VERSION}"

ENV POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=C.UTF-8"

EXPOSE 5432

COPY postgresql-healthcheck.sh /usr/local/bin/postgresql-healthcheck

RUN chmod +x /usr/local/bin/postgresql-healthcheck

# O entrypoint oficial da imagem base inicializa o cluster e executa scripts
# montados em /docker-entrypoint-initdb.d de forma síncrona no primeiro bootstrap.
