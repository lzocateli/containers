FROM gvenzl/oracle-xe:21-slim

USER root

VOLUME /docker-entrypoint-initdb.d

ENV ORACLE_DATABASE_CHARSET=AL32UTF8

EXPOSE 1521

COPY ./docker-entrypoint.sh             /usr/local/bin/
COPY ./docker-entrypoint-initdb.sh      /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh 
RUN chmod +x /usr/local/bin/docker-entrypoint-initdb.sh

RUN mkdir -p -m 777 /opt/oracle/oradata
RUN mkdir -p -m 777 /opt/oracle/scripts
RUN chmod -R 777 /opt/oracle/oradata /opt/oracle/scripts

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

#USER oracle
