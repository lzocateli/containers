FROM postgres:17-bookworm
	
USER root

VOLUME /docker-entrypoint-initdb.d

ENV PG_DATABASE_ENCODING=UTF8

EXPOSE 5432

COPY ./docker-entrypoint.sh             /usr/local/bin/
COPY ./docker-entrypoint-initdb.sh      /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh 
RUN chmod +x /usr/local/bin/docker-entrypoint-initdb.sh

RUN mkdir -p -m 700 /var/lib/postgresql
RUN mkdir -p -m 700 /var/lib/postgresql/data
RUN mkdir -p -m 777 /var/log/postgresql
RUN mkdir -p -m 777 /var/run/postgresql
RUN chown -R postgres:postgres /var/lib/postgresql /var/log/postgresql /var/run/postgresql
#RUN chown -R postgres /var/lib/postgresql /var/log/postgresql /var/run/postgresql


ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

RUN mkdir -p /home/postgres/

RUN chown postgres /home/postgres/

#USER postgres
