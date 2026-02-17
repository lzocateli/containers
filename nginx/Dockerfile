ARG BUILDPLATFORM=linux/amd64

FROM --platform=$BUILDPLATFORM nginx:1.25.0-bullseye

RUN apt update -y \
    && apt upgrade -y

RUN apt install -y \
    nginx-extras \
    nano \
    net-tools \
    iputils-ping \
    telnet \
    traceroute

COPY html /usr/share/nginx/html
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./custom-error.locations /etc/nginx/conf.d/

RUN ln -s -f /usr/share/nginx/html/custom-error-page/custom-error-page.html /usr/share/nginx/html/index.html
