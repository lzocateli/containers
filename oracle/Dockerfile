# syntax=docker/dockerfile:1
FROM gvenzl/oracle-free:23-slim

LABEL org.opencontainers.image.title="lzocateli/oracle" \
	org.opencontainers.image.description="Oracle Database Free 23c para uso em contêineres." \
	org.opencontainers.image.source="https://github.com/lzocateli/containers" \
	org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/oracle" \
	org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/oracle" \
	org.opencontainers.image.version="23-slim"

USER root

ENV ORACLE_DATABASE_CHARSET=AL32UTF8

EXPOSE 1521

RUN install -d -o oracle -g oinstall -m 0770 /opt/oracle/oradata /opt/oracle/scripts

VOLUME /opt/oracle/oradata

USER oracle
