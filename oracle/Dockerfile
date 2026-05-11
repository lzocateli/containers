FROM gvenzl/oracle-free:23-slim

USER root

VOLUME /container-entrypoint-initdb.d

ENV ORACLE_DATABASE_CHARSET=AL32UTF8

EXPOSE 1521

RUN mkdir -p -m 777 /opt/oracle/oradata
RUN mkdir -p -m 777 /opt/oracle/scripts
RUN chmod -R 777 /opt/oracle/oradata /opt/oracle/scripts

USER oracle
