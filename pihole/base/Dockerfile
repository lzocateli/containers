FROM pihole/pihole:2024.07.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install unbound -y

RUN mkdir -p /etc/unbound/unbound.conf.d/
COPY ./pi-hole.conf /etc/unbound/unbound.conf.d/


RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/unbound
RUN mkdir /etc/s6-overlay/s6-rc.d/unbound
RUN echo oneshot | tee /etc/s6-overlay/s6-rc.d/unbound/type 
RUN tee /etc/s6-overlay/s6-rc.d/unbound/up <<EOF
foreground { echo "starting unbound..." }
/etc/init.d/unbound start
EOF
